-- Migration 202608210004: Guide Quality & Attribution
-- 1. Enforces minimum 2 stops on guide submissions at server-level
-- 2. Adds author attribution (display name and creator badge status) to published_guides
-- 3. Updates admin moderation to derive author attribution safely

-- 1. Add author attribution columns to published_guides
alter table public.published_guides
  add column if not exists author_display_name text not null default 'LiveLocal',
  add column if not exists author_is_creator boolean not null default false;

-- 2. Update submit_guide to enforce minimum 2 stops and raise GUIDE_MINIMUM_STOPS_REQUIRED
create or replace function public.submit_guide(
  p_title text,
  p_location_name text,
  p_state text,
  p_route_overview text,
  p_stops jsonb,
  p_walking_sequence jsonb,
  p_estimated_duration text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare entity public.guides;
declare revision public.guide_revisions;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot submit guides';
  end if;
  perform private.assert_current_ugc_rules_accepted();
  if not private.valid_text_array(p_stops, 300)
      or not private.valid_text_array(p_walking_sequence, 500)
      or jsonb_array_length(p_stops) <> jsonb_array_length(p_walking_sequence)
      or jsonb_array_length(p_stops) < 2 then
    raise exception using errcode = '22023', message = 'GUIDE_MINIMUM_STOPS_REQUIRED';
  end if;
  perform private.assert_no_banned_words(p_title);
  perform private.assert_no_banned_words(p_route_overview);
  perform private.assert_no_banned_words(p_stops::text);
  perform private.assert_no_banned_words(p_walking_sequence::text);

  insert into public.guides (creator_id) values (auth.uid()) returning * into entity;
  insert into public.guide_revisions (
    guide_id, revision_number, author_id, status, title, location_name, state,
    route_overview, stops, walking_sequence, estimated_duration, submitted_at
  ) values (
    entity.id, 1, auth.uid(), 'submitted', btrim(p_title),
    btrim(p_location_name), btrim(p_state), btrim(p_route_overview), p_stops,
    p_walking_sequence, btrim(p_estimated_duration), clock_timestamp()
  ) returning * into revision;
  update public.guides set current_revision_id = revision.id where id = entity.id;
  return jsonb_build_object(
    'guide_id', entity.id, 'revision_id', revision.id,
    'version', entity.version, 'status', revision.status
  );
end;
$$;

-- 3. Update admin_moderate_guide_revision to populate author attribution
create or replace function public.admin_moderate_guide_revision(
  p_revision_id uuid,
  p_decision text,
  p_reason text,
  p_expected_version integer
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare entity public.guides;
declare revision public.guide_revisions;
declare next_version integer;
declare v_author_display_name text;
declare v_author_is_creator boolean;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'Admin permission required';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception using errcode = '22023', message = 'Invalid guide decision';
  end if;
  if char_length(btrim(coalesce(p_reason, ''))) < 3 then
    raise exception using errcode = '22023', message = 'Decision reason required';
  end if;
  select * into revision from public.guide_revisions
  where id = p_revision_id and status in ('submitted', 'under_review') for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Guide submission not found';
  end if;
  select * into entity from public.guides where id = revision.guide_id for update;
  if entity.version <> p_expected_version or entity.current_revision_id <> revision.id then
    raise exception using errcode = '40001', message = 'Guide changed concurrently';
  end if;
  next_version := entity.version + 1;
  update public.guide_revisions set status = p_decision::public.content_revision_status,
    decision_reason = btrim(p_reason), decided_at = clock_timestamp(),
    updated_at = clock_timestamp() where id = revision.id;
  update public.guides set
    published_revision_id = case when p_decision = 'approved' then revision.id else published_revision_id end,
    version = next_version where id = entity.id;
  if p_decision = 'approved' then
    select
      case
        when coalesce(ur.role, 'tourist') = 'admin' then 'LiveLocal'
        else coalesce(p.display_name, 'LiveLocal')
      end,
      (coalesce(ur.role, 'tourist') = 'influencer')
    into v_author_display_name, v_author_is_creator
    from public.profiles p
    left join public.user_roles ur on ur.user_id = p.id
    where p.id = revision.author_id;

    v_author_display_name := coalesce(v_author_display_name, 'LiveLocal');
    v_author_is_creator := coalesce(v_author_is_creator, false);

    insert into public.published_guides (
      id, revision_id, title, location_name, state, route_overview,
      stops, walking_sequence, estimated_duration,
      author_display_name, author_is_creator
    ) values (
      entity.id, revision.id, revision.title, revision.location_name,
      revision.state, revision.route_overview, revision.stops,
      revision.walking_sequence, revision.estimated_duration,
      v_author_display_name, v_author_is_creator
    ) on conflict (id) do update set
      revision_id = excluded.revision_id, title = excluded.title,
      location_name = excluded.location_name, state = excluded.state,
      route_overview = excluded.route_overview, stops = excluded.stops,
      walking_sequence = excluded.walking_sequence,
      estimated_duration = excluded.estimated_duration,
      author_display_name = excluded.author_display_name,
      author_is_creator = excluded.author_is_creator,
      updated_at = clock_timestamp();
  end if;
  insert into public.guide_moderation_decisions (
    guide_id, revision_id, decision, reason, actor_id, guide_version
  ) values (entity.id, revision.id, p_decision, btrim(p_reason), auth.uid(), next_version);
  insert into public.audit_events (actor_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'admin.guide_' || p_decision, 'guide', entity.id,
    btrim(p_reason), jsonb_build_object('revision_id', revision.id, 'version', next_version));
  return jsonb_build_object('guide_id', entity.id, 'revision_id', revision.id,
    'version', next_version, 'status', p_decision);
end;
$$;

-- 4. Backfill existing published_guides
update public.published_guides pg
set
  author_display_name = coalesce(
    case
      when coalesce(ur.role, 'tourist') = 'admin' then 'LiveLocal'
      else p.display_name
    end,
    'LiveLocal'
  ),
  author_is_creator = (coalesce(ur.role, 'tourist') = 'influencer')
from public.guide_revisions gr
left join public.profiles p on p.id = gr.author_id
left join public.user_roles ur on ur.user_id = gr.author_id
where gr.id = pg.revision_id;
