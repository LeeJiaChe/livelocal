-- Migration 202608210005: Guide Active Role Attribution Fix
-- Ensures guide attribution on admin moderation and existing published guides
-- uses the author's ACTIVE role (via private.current_role with revoked_at is null)
-- rather than unbounded role history joins.

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
declare v_author_role public.app_role;
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
    v_author_role := private.current_role(revision.author_id);
    if v_author_role = 'admin' then
      v_author_display_name := 'LiveLocal';
      v_author_is_creator := false;
    elsif v_author_role = 'influencer' then
      select coalesce(nullif(btrim(display_name), ''), 'LiveLocal Creator')
      into v_author_display_name
      from public.profiles where id = revision.author_id;
      v_author_display_name := coalesce(v_author_display_name, 'LiveLocal Creator');
      v_author_is_creator := true;
    elsif v_author_role = 'tourist' then
      select coalesce(nullif(btrim(display_name), ''), 'LiveLocal Explorer')
      into v_author_display_name
      from public.profiles where id = revision.author_id;
      v_author_display_name := coalesce(v_author_display_name, 'LiveLocal Explorer');
      v_author_is_creator := false;
    else
      v_author_display_name := 'LiveLocal';
      v_author_is_creator := false;
    end if;

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

-- Backfill / repair existing published_guides using active role only
update public.published_guides pg
set
  author_display_name = case
    when private.current_role(gr.author_id) = 'admin' then 'LiveLocal'
    when private.current_role(gr.author_id) = 'influencer'
      then coalesce(nullif(btrim(p.display_name), ''), 'LiveLocal Creator')
    when private.current_role(gr.author_id) = 'tourist'
      then coalesce(nullif(btrim(p.display_name), ''), 'LiveLocal Explorer')
    else 'LiveLocal'
  end,
  author_is_creator = (private.current_role(gr.author_id) = 'influencer'),
  updated_at = clock_timestamp()
from public.guide_revisions gr
left join public.profiles p on p.id = gr.author_id
where gr.id = pg.revision_id;
