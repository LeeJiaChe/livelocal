begin;

alter table public.guide_revisions
  add column submitted_at timestamptz,
  add column decided_at timestamptz,
  add column decision_reason text
    check (decision_reason is null or char_length(btrim(decision_reason)) between 3 and 1000);

create table public.guide_moderation_decisions (
  id uuid primary key default gen_random_uuid(),
  guide_id uuid not null references public.guides(id) on delete cascade,
  revision_id uuid not null references public.guide_revisions(id) on delete restrict,
  decision text not null check (decision in ('approved', 'rejected')),
  reason text not null check (char_length(btrim(reason)) between 3 and 1000),
  actor_id uuid references auth.users(id) on delete set null,
  guide_version integer not null,
  created_at timestamptz not null default clock_timestamp(),
  unique (guide_id, guide_version)
);

alter table public.guide_moderation_decisions enable row level security;
create policy guide_moderation_decisions_admin_select
  on public.guide_moderation_decisions for select to authenticated
  using (private.is_admin());
create policy guides_owner_select on public.guides for select to authenticated
  using (creator_id = (select auth.uid()));
create policy guide_revisions_owner_select on public.guide_revisions
  for select to authenticated using (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.guides guide
      where guide.id = guide_revisions.guide_id
        and guide.creator_id = (select auth.uid())
    )
  );

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
      or jsonb_array_length(p_stops) <> jsonb_array_length(p_walking_sequence) then
    raise exception using errcode = '22023', message = 'Invalid guide stops';
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
    'estimated_duration', revision.estimated_duration,
    'status', revision.status, 'decision_reason', revision.decision_reason
  )
  from public.guides guide
  join public.guide_revisions revision on revision.id = guide.current_revision_id
  where guide.creator_id = auth.uid()
  order by revision.updated_at desc;
$$;

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
    insert into public.published_guides (
      id, revision_id, title, location_name, state, route_overview,
      stops, walking_sequence, estimated_duration
    ) values (
      entity.id, revision.id, revision.title, revision.location_name,
      revision.state, revision.route_overview, revision.stops,
      revision.walking_sequence, revision.estimated_duration
    ) on conflict (id) do update set
      revision_id = excluded.revision_id, title = excluded.title,
      location_name = excluded.location_name, state = excluded.state,
      route_overview = excluded.route_overview, stops = excluded.stops,
      walking_sequence = excluded.walking_sequence,
      estimated_duration = excluded.estimated_duration,
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

create table public.spot_upvotes (
  spot_id uuid not null references public.spots(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default clock_timestamp(),
  primary key (spot_id, user_id)
);
alter table public.spot_upvotes enable row level security;
create policy spot_upvotes_owner_select on public.spot_upvotes
  for select to authenticated using (user_id = (select auth.uid()));
alter table public.published_spots add column upvote_count integer not null default 0
  check (upvote_count >= 0);

create or replace function public.toggle_spot_upvote(p_spot_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare now_upvoted boolean;
declare total integer;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot vote';
  end if;
  if not exists (select 1 from public.published_spots where id = p_spot_id) then
    raise exception using errcode = 'P0002', message = 'Published spot not found';
  end if;
  delete from public.spot_upvotes where spot_id = p_spot_id and user_id = auth.uid();
  if found then
    now_upvoted := false;
  else
    insert into public.spot_upvotes (spot_id, user_id) values (p_spot_id, auth.uid())
    on conflict do nothing;
    now_upvoted := true;
  end if;
  select count(*)::integer into total from public.spot_upvotes where spot_id = p_spot_id;
  update public.published_spots set upvote_count = total where id = p_spot_id;
  return jsonb_build_object('upvoted', now_upvoted, 'upvote_count', total);
end;
$$;

revoke all on table public.guide_moderation_decisions from anon, authenticated;
revoke all on table public.spot_upvotes from anon, authenticated;
grant select on table public.guide_moderation_decisions to authenticated;
grant select on table public.spot_upvotes to authenticated;
revoke all on function public.submit_guide(text,text,text,text,jsonb,jsonb,text) from public;
revoke all on function public.list_my_guide_submissions() from public;
revoke all on function public.admin_moderate_guide_revision(uuid,text,text,integer) from public;
revoke all on function public.toggle_spot_upvote(uuid) from public;
grant execute on function public.submit_guide(text,text,text,text,jsonb,jsonb,text) to authenticated;
grant execute on function public.list_my_guide_submissions() to authenticated;
grant execute on function public.admin_moderate_guide_revision(uuid,text,text,integer) to authenticated;
grant execute on function public.toggle_spot_upvote(uuid) to authenticated;

create table public.review_votes (
  review_id uuid not null references public.reviews(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  vote smallint not null check (vote in (-1, 1)),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (review_id, user_id)
);
alter table public.review_votes enable row level security;
create policy review_votes_owner_select on public.review_votes
  for select to authenticated using (user_id = (select auth.uid()));
alter table public.public_reviews
  add column likes_count integer not null default 0 check (likes_count >= 0),
  add column dislikes_count integer not null default 0 check (dislikes_count >= 0);

create or replace function public.set_review_vote(p_review_id uuid, p_vote integer)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare likes integer;
declare dislikes integer;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot react to reviews';
  end if;
  if p_vote not in (-1, 0, 1) then
    raise exception using errcode = '22023', message = 'Invalid review vote';
  end if;
  if not exists (select 1 from public.public_reviews where id = p_review_id) then
    raise exception using errcode = 'P0002', message = 'Published review not found';
  end if;
  if p_vote = 0 then
    delete from public.review_votes
    where review_id = p_review_id and user_id = auth.uid();
  else
    insert into public.review_votes (review_id, user_id, vote)
    values (p_review_id, auth.uid(), p_vote)
    on conflict (review_id, user_id) do update
      set vote = excluded.vote, updated_at = clock_timestamp();
  end if;
  select count(*) filter (where vote = 1)::integer,
    count(*) filter (where vote = -1)::integer
  into likes, dislikes from public.review_votes where review_id = p_review_id;
  update public.public_reviews set likes_count = likes, dislikes_count = dislikes
  where id = p_review_id;
  return jsonb_build_object(
    'user_vote', nullif(p_vote, 0),
    'likes_count', likes,
    'dislikes_count', dislikes
  );
end;
$$;

revoke all on table public.review_votes from anon, authenticated;
grant select on table public.review_votes to authenticated;
revoke all on function public.set_review_vote(uuid, integer) from public;
grant execute on function public.set_review_vote(uuid, integer) to authenticated;

commit;
