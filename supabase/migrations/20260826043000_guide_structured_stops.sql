begin;

alter table public.guide_revisions
  add column stop_details jsonb not null default '[]'::jsonb;

alter table public.published_guides
  add column stop_details jsonb not null default '[]'::jsonb;

create or replace function private.assert_valid_guide_stop_details(
  p_stop_details jsonb
)
returns void
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare item jsonb;
declare listing_id uuid;
begin
  if jsonb_typeof(p_stop_details) <> 'array'
      or jsonb_array_length(p_stop_details) not between 2 and 30 then
    raise exception using errcode = '22023', message = 'INVALID_GUIDE_STOP_DETAILS';
  end if;

  for item in select value from jsonb_array_elements(p_stop_details)
  loop
    if jsonb_typeof(item) <> 'object'
        or item->>'kind' not in ('listing', 'custom')
        or char_length(btrim(coalesce(item->>'name', ''))) not between 2 and 300
        or char_length(btrim(coalesce(item->>'instruction', ''))) not between 3 and 500 then
      raise exception using errcode = '22023', message = 'INVALID_GUIDE_STOP_DETAILS';
    end if;

    if item->>'kind' = 'listing' then
      if item->>'listing_type' not in ('spot', 'restaurant')
          or coalesce(item->>'listing_id', '') !~
            '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$' then
        raise exception using errcode = '22023', message = 'INVALID_GUIDE_LISTING_STOP';
      end if;
      listing_id := (item->>'listing_id')::uuid;
      if (item->>'listing_type' = 'spot' and not exists (
            select 1 from public.published_spots where id = listing_id
          )) or (item->>'listing_type' = 'restaurant' and not exists (
            select 1 from public.published_restaurants where id = listing_id
          )) then
        raise exception using errcode = '23503', message = 'GUIDE_LISTING_STOP_UNAVAILABLE';
      end if;
    elsif item ? 'listing_id' or item ? 'listing_type' then
      raise exception using errcode = '22023', message = 'INVALID_CUSTOM_GUIDE_STOP';
    end if;
  end loop;
end;
$$;

revoke all on function private.assert_valid_guide_stop_details(jsonb) from public;

update public.guide_revisions revision
set stop_details = details.value
from lateral (
  select coalesce(jsonb_agg(jsonb_build_object(
    'kind', 'custom',
    'name', stop.value #>> '{}',
    'instruction', coalesce(revision.walking_sequence->(stop.ordinality - 1), '"Continue to the next stop"'::jsonb) #>> '{}'
  ) order by stop.ordinality), '[]'::jsonb) as value
  from jsonb_array_elements(revision.stops) with ordinality as stop(value, ordinality)
) details;

update public.published_guides publication
set stop_details = revision.stop_details
from public.guide_revisions revision
where revision.id = publication.revision_id;

alter table public.guide_revisions
  add constraint guide_stop_details_valid check (
    jsonb_typeof(stop_details) = 'array'
    and (jsonb_array_length(stop_details) = 0
      or jsonb_array_length(stop_details) between 2 and 30)
  );

alter table public.published_guides
  add constraint published_guide_stop_details_valid check (
    jsonb_typeof(stop_details) = 'array'
    and jsonb_array_length(stop_details) between 2 and 30
  );

create or replace function private.sync_published_guide_stop_details()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  select stop_details into new.stop_details
  from public.guide_revisions where id = new.revision_id;
  return new;
end;
$$;

create trigger published_guide_stop_details_sync
before insert or update of revision_id on public.published_guides
for each row execute function private.sync_published_guide_stop_details();

revoke all on function private.sync_published_guide_stop_details() from public;

create function public.submit_guide_v2(
  p_title text,
  p_location_name text,
  p_state text,
  p_route_overview text,
  p_stops jsonb,
  p_walking_sequence jsonb,
  p_stop_details jsonb,
  p_estimated_duration text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare result jsonb;
begin
  perform private.assert_valid_guide_stop_details(p_stop_details);
  if jsonb_array_length(p_stop_details) <> jsonb_array_length(p_stops) then
    raise exception using errcode = '22023', message = 'GUIDE_STOPS_MISALIGNED';
  end if;
  perform private.assert_no_banned_words(p_stop_details::text);
  result := public.submit_guide(
    p_title, p_location_name, p_state, p_route_overview,
    p_stops, p_walking_sequence, p_estimated_duration
  );
  update public.guide_revisions
  set stop_details = p_stop_details
  where id = (result->>'revision_id')::uuid and author_id = auth.uid();
  return result;
end;
$$;

create function public.admin_save_guide_draft_v2(
  p_guide_id uuid,
  p_title text,
  p_location_name text,
  p_state text,
  p_route_overview text,
  p_stops jsonb,
  p_walking_sequence jsonb,
  p_stop_details jsonb,
  p_estimated_duration text,
  p_expected_version integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare result jsonb;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'Admin permission required';
  end if;
  perform private.assert_valid_guide_stop_details(p_stop_details);
  if jsonb_array_length(p_stop_details) <> jsonb_array_length(p_stops) then
    raise exception using errcode = '22023', message = 'GUIDE_STOPS_MISALIGNED';
  end if;
  result := public.admin_save_guide_draft(
    p_guide_id, p_title, p_location_name, p_state, p_route_overview,
    p_stops, p_walking_sequence, p_estimated_duration, p_expected_version
  );
  update public.guide_revisions
  set stop_details = p_stop_details
  where id = (result->>'revision_id')::uuid;
  return result;
end;
$$;

create or replace function public.list_my_guide_submissions()
returns setof jsonb
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select jsonb_build_object(
    'id', guide.id, 'revision_id', revision.id, 'version', guide.version,
    'title', revision.title, 'location_name', revision.location_name,
    'state', revision.state, 'route_overview', revision.route_overview,
    'stops', revision.stops, 'walking_sequence', revision.walking_sequence,
    'stop_details', revision.stop_details,
    'estimated_duration', revision.estimated_duration,
    'status', revision.status, 'decision_reason', revision.decision_reason
  )
  from public.guides guide
  join public.guide_revisions revision on revision.id = guide.current_revision_id
  where guide.creator_id = auth.uid()
  order by revision.updated_at desc;
$$;

revoke all on function public.submit_guide_v2(text,text,text,text,jsonb,jsonb,jsonb,text) from public;
revoke all on function public.admin_save_guide_draft_v2(uuid,text,text,text,text,jsonb,jsonb,jsonb,text,integer) from public;
revoke execute on function public.submit_guide(text,text,text,text,jsonb,jsonb,text) from authenticated;
revoke execute on function public.admin_save_guide_draft(uuid,text,text,text,text,jsonb,jsonb,text,integer) from authenticated;
grant execute on function public.submit_guide_v2(text,text,text,text,jsonb,jsonb,jsonb,text) to authenticated;
grant execute on function public.admin_save_guide_draft_v2(uuid,text,text,text,text,jsonb,jsonb,jsonb,text,integer) to authenticated;

commit;
