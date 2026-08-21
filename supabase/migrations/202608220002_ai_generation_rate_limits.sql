begin;

-- AI generation rate limiting and duplicate request tracking table.
-- Server-owned and private: mobile clients have no direct read/write grants.
create table if not exists public.ai_generation_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_hash text not null,
  platform text not null check (platform in ('tiktok', 'instagram')),
  requested_at timestamptz not null default clock_timestamp(),
  outcome text not null default 'started' check (
    outcome in ('started', 'succeeded', 'failed', 'rate_limited')
  )
);

create index if not exists ai_generation_usage_user_window_idx
  on public.ai_generation_usage(user_id, requested_at);

create index if not exists ai_generation_usage_user_source_idx
  on public.ai_generation_usage(user_id, source_hash, requested_at);

alter table public.ai_generation_usage enable row level security;

revoke all on table public.ai_generation_usage
  from public, anon, authenticated;
grant all on table public.ai_generation_usage to service_role;

-- Quota checking and usage tracking function for Edge Functions
create or replace function public.check_and_record_ai_generation_quota(
  p_user_id uuid,
  p_source_hash text,
  p_platform text,
  p_hourly_limit integer default 10,
  p_daily_limit integer default 50,
  p_cooldown_seconds integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_recent_duplicate timestamptz;
  v_hourly_count integer;
  v_daily_count integer;
  v_new_usage_id uuid;
  v_cooldown_remaining integer;
begin
  -- 1. Cooldown / Duplicate check (same user + same source hash within cooldown)
  select max(requested_at) into v_recent_duplicate
  from public.ai_generation_usage
  where user_id = p_user_id
    and source_hash = p_source_hash
    and requested_at > (clock_timestamp() - (p_cooldown_seconds || ' seconds')::interval)
    and outcome in ('started', 'succeeded');

  if v_recent_duplicate is not null then
    v_cooldown_remaining := greatest(
      1,
      extract(epoch from (v_recent_duplicate + (p_cooldown_seconds || ' seconds')::interval - clock_timestamp()))::integer
    );
    return jsonb_build_object(
      'allowed', false,
      'error_code', 'COOLDOWN',
      'retry_after_seconds', v_cooldown_remaining
    );
  end if;

  -- 2. Hourly quota check (last 1 hour)
  select count(*) into v_hourly_count
  from public.ai_generation_usage
  where user_id = p_user_id
    and requested_at > (clock_timestamp() - interval '1 hour')
    and outcome != 'rate_limited';

  if v_hourly_count >= p_hourly_limit then
    return jsonb_build_object(
      'allowed', false,
      'error_code', 'HOURLY_LIMIT_EXCEEDED',
      'retry_after_seconds', 3600
    );
  end if;

  -- 3. Daily quota check (last 24 hours)
  select count(*) into v_daily_count
  from public.ai_generation_usage
  where user_id = p_user_id
    and requested_at > (clock_timestamp() - interval '24 hours')
    and outcome != 'rate_limited';

  if v_daily_count >= p_daily_limit then
    return jsonb_build_object(
      'allowed', false,
      'error_code', 'DAILY_LIMIT_EXCEEDED',
      'retry_after_seconds', 86400
    );
  end if;

  -- 4. Record new usage entry
  insert into public.ai_generation_usage (
    user_id, source_hash, platform, outcome
  ) values (
    p_user_id, p_source_hash, p_platform, 'started'
  ) returning id into v_new_usage_id;

  return jsonb_build_object(
    'allowed', true,
    'usage_id', v_new_usage_id
  );
end;
$$;

create or replace function public.record_ai_generation_outcome(
  p_usage_id uuid,
  p_outcome text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  update public.ai_generation_usage
  set outcome = p_outcome
  where id = p_usage_id;
end;
$$;

revoke all on function public.check_and_record_ai_generation_quota(uuid, text, text, integer, integer, integer)
  from public, anon, authenticated;
grant execute on function public.check_and_record_ai_generation_quota(uuid, text, text, integer, integer, integer)
  to service_role;

revoke all on function public.record_ai_generation_outcome(uuid, text)
  from public, anon, authenticated;
grant execute on function public.record_ai_generation_outcome(uuid, text)
  to service_role;

-- AI Provenance on restaurant revisions
alter table public.restaurant_revisions
  add column if not exists ai_assisted boolean not null default false,
  add column if not exists ai_source_platform text null
    check (ai_source_platform in ('instagram', 'tiktok'));

-- Drop earlier overloads to avoid ambiguous function resolution
drop function if exists public.create_restaurant_draft(
  text, text, text, text, text, text, text, text, text, double precision, double precision
);

drop function if exists public.save_restaurant_revision_draft(
  uuid, text, text, text, text, text, text, text, text, text, double precision, double precision
);

create or replace function public.create_restaurant_draft(
  p_name text,
  p_address text,
  p_state text,
  p_city text,
  p_cuisine_type text,
  p_price_range text,
  p_reviewed_dishes text,
  p_social_media_url text,
  p_cover_image_path text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_ai_assisted boolean default false,
  p_ai_source_platform text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  created_id uuid;
  revision_id uuid;
begin
  if not private.can_use_protected_features()
      or private.current_role(auth.uid()) <> 'influencer' then
    raise exception using errcode = '42501',
      message = 'Approved creator role required';
  end if;
  if not private.is_supported_social_url(p_social_media_url, null) then
    raise exception using errcode = '22023',
      message = 'Unsupported social URL';
  end if;
  if p_cover_image_path is not null
      and p_cover_image_path !~ (
        '^' || auth.uid()::text || '/[A-Za-z0-9_-]+\.(jpg|png|webp)$'
      ) then
    raise exception using errcode = '22023',
      message = 'Invalid restaurant image path';
  end if;
  if p_ai_source_platform is not null
      and p_ai_source_platform not in ('instagram', 'tiktok') then
    raise exception using errcode = '22023',
      message = 'Invalid AI source platform';
  end if;

  insert into public.restaurants (owner_id)
  values (auth.uid())
  returning id into created_id;

  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    cover_image_path, latitude, longitude, ai_assisted, ai_source_platform
  ) values (
    created_id, 1, auth.uid(), btrim(p_name), btrim(p_address), btrim(p_state),
    btrim(p_city), btrim(p_cuisine_type), p_price_range,
    btrim(p_reviewed_dishes), btrim(p_social_media_url), p_cover_image_path,
    p_latitude, p_longitude, coalesce(p_ai_assisted, false), p_ai_source_platform
  ) returning id into revision_id;

  update public.restaurants
  set current_revision_id = revision_id
  where id = created_id;

  return jsonb_build_object(
    'restaurant_id', created_id,
    'revision_id', revision_id,
    'image_path', p_cover_image_path,
    'status', 'draft',
    'probable_duplicates', private.probable_restaurant_duplicates(
      p_name, p_address, p_latitude, p_longitude, created_id
    )
  );
end;
$$;

create or replace function public.save_restaurant_revision_draft(
  p_source_revision_id uuid,
  p_name text,
  p_address text,
  p_state text,
  p_city text,
  p_cuisine_type text,
  p_price_range text,
  p_reviewed_dishes text,
  p_social_media_url text,
  p_cover_image_path text,
  p_latitude double precision,
  p_longitude double precision,
  p_ai_assisted boolean default false,
  p_ai_source_platform text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
declare
  entity public.restaurants;
  source public.restaurant_revisions;
  saved public.restaurant_revisions;
  next_number integer;
  selected_image_path text;
begin
  if not private.can_use_protected_features()
      or private.current_role(auth.uid()) <> 'influencer' then
    raise exception using errcode = '42501', message = 'Approved creator role required';
  end if;
  if not private.is_supported_social_url(p_social_media_url, null) then
    raise exception using errcode = '22023', message = 'Unsupported social URL';
  end if;
  if p_ai_source_platform is not null
      and p_ai_source_platform not in ('instagram', 'tiktok') then
    raise exception using errcode = '22023', message = 'Invalid AI source platform';
  end if;

  select * into entity
  from public.restaurants
  where owner_id = auth.uid()
    and current_revision_id = p_source_revision_id
    and ownership_status = 'creator_owned'
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Current owned restaurant revision not found';
  end if;

  select * into source
  from public.restaurant_revisions
  where id = p_source_revision_id
  for update;
  if source.status not in (
    'draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn'
  ) then
    raise exception using errcode = '22023', message = 'Restaurant revision cannot be edited';
  end if;

  selected_image_path := coalesce(p_cover_image_path, source.cover_image_path);
  if selected_image_path is null
      or selected_image_path !~ ('^' || auth.uid()::text || '/[A-Za-z0-9_-]+\.(jpg|png|webp)$')
      or not exists (
        select 1 from storage.objects object
        where object.bucket_id = 'restaurant-images'
          and object.name = selected_image_path
      ) then
    raise exception using errcode = '22023', message = 'Valid restaurant image required';
  end if;

  if source.status = 'draft' then
    update public.restaurant_revisions
    set name = btrim(p_name),
        address = btrim(p_address),
        state = btrim(p_state),
        city = btrim(p_city),
        cuisine_type = btrim(p_cuisine_type),
        price_range = p_price_range,
        reviewed_dishes = btrim(p_reviewed_dishes),
        social_media_url = btrim(p_social_media_url),
        cover_image_path = selected_image_path,
        latitude = p_latitude,
        longitude = p_longitude,
        ai_assisted = coalesce(p_ai_assisted, false),
        ai_source_platform = p_ai_source_platform,
        decision_reason = null
    where id = source.id
    returning * into saved;
  else
    select coalesce(max(revision_number), 0) + 1 into next_number
    from public.restaurant_revisions
    where restaurant_id = entity.id;

    insert into public.restaurant_revisions (
      restaurant_id, revision_number, author_id, name, address, state, city,
      cuisine_type, price_range, reviewed_dishes, social_media_url,
      cover_image_path, latitude, longitude, status, superseded_by_revision_id,
      ai_assisted, ai_source_platform
    ) values (
      entity.id, next_number, auth.uid(), btrim(p_name), btrim(p_address),
      btrim(p_state), btrim(p_city), btrim(p_cuisine_type), p_price_range,
      btrim(p_reviewed_dishes), btrim(p_social_media_url), selected_image_path,
      p_latitude, p_longitude, 'draft', null,
      coalesce(p_ai_assisted, false), p_ai_source_platform
    ) returning * into saved;

    update public.restaurants
    set current_revision_id = saved.id
    where id = entity.id;
  end if;

  return jsonb_build_object(
    'restaurant_id', entity.id,
    'revision_id', saved.id,
    'image_path', saved.cover_image_path,
    'status', saved.status,
    'probable_duplicates', private.probable_restaurant_duplicates(
      p_name, p_address, p_latitude, p_longitude, entity.id
    )
  );
end;
$$;

revoke all on function public.create_restaurant_draft(text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text) from public;
grant execute on function public.create_restaurant_draft(text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text) to authenticated;

revoke all on function public.save_restaurant_revision_draft(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text) from public;
grant execute on function public.save_restaurant_revision_draft(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text) to authenticated;

commit;
