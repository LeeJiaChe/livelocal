begin;

-- Persist only stable external-provider identity. Display data remains live
-- provider data and is resolved by the Edge Functions on demand.
alter table public.saved_places
  add column external_provider text,
  add column external_place_id text;

alter table public.saved_places
  drop constraint saved_place_exactly_one_target,
  add constraint saved_place_external_pair check (
    (external_provider is null) = (external_place_id is null)
  ),
  add constraint saved_place_external_provider check (
    external_provider is null or external_provider = 'google'
  ),
  add constraint saved_place_external_id check (
    external_place_id is null
    or external_place_id ~ '^[A-Za-z0-9_-]{8,256}$'
  ),
  add constraint saved_place_exactly_one_target check (
    (spot_id is not null)::integer
      + (restaurant_id is not null)::integer
      + (external_place_id is not null)::integer = 1
  );

create unique index saved_places_one_external_per_user
  on public.saved_places(user_id, external_provider, external_place_id)
  where external_place_id is not null;

alter table public.itinerary_items
  add column external_provider text,
  add column external_place_id text;

alter table public.itinerary_items
  drop constraint itinerary_item_exactly_one_target,
  add constraint itinerary_item_external_pair check (
    (external_provider is null) = (external_place_id is null)
  ),
  add constraint itinerary_item_external_provider check (
    external_provider is null or external_provider = 'google'
  ),
  add constraint itinerary_item_external_id check (
    external_place_id is null
    or external_place_id ~ '^[A-Za-z0-9_-]{8,256}$'
  ),
  add constraint itinerary_item_exactly_one_target check (
    (spot_id is not null)::integer
      + (restaurant_id is not null)::integer
      + (external_place_id is not null)::integer = 1
  );

create unique index itinerary_items_one_external
  on public.itinerary_items(itinerary_id, external_provider, external_place_id)
  where external_place_id is not null;

create or replace function public.list_my_saved_collections()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot view saved collections';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'user_id', c.user_id,
      'name', c.name,
      'description', c.description,
      'created_at', c.created_at,
      'updated_at', c.updated_at,
      'item_count', coalesce(items_summary.total_items, 0),
      'spot_count', coalesce(items_summary.total_spots, 0),
      'restaurant_count', coalesce(items_summary.total_restaurants, 0),
      'external_count', coalesce(items_summary.total_external, 0),
      'cover_target_type', items_summary.sample_target_type,
      'cover_image_url', items_summary.sample_image_url,
      'cover_image_path', items_summary.sample_image_url
    ) order by c.updated_at desc
  ), '[]'::jsonb)
  into result
  from public.saved_collections c
  left join lateral (
    select
      count(sci.id) as total_items,
      count(sp.spot_id) as total_spots,
      count(sp.restaurant_id) as total_restaurants,
      count(sp.external_place_id) as total_external,
      (
        select case
          when sp_sub.spot_id is not null then 'spot'
          when sp_sub.restaurant_id is not null then 'restaurant'
          else 'external'
        end
        from public.saved_collection_items sci_sub
        join public.saved_places sp_sub on sp_sub.id = sci_sub.saved_place_id
        where sci_sub.collection_id = c.id
        order by sci_sub.added_at desc
        limit 1
      ) as sample_target_type,
      (
        select coalesce(
          (select ps.image_path from public.published_spots ps where ps.id = sp_sub.spot_id),
          (select pr.cover_image_path from public.published_restaurants pr where pr.id = sp_sub.restaurant_id)
        )
        from public.saved_collection_items sci_sub
        join public.saved_places sp_sub on sp_sub.id = sci_sub.saved_place_id
        where sci_sub.collection_id = c.id
        order by sci_sub.added_at desc
        limit 1
      ) as sample_image_url
    from public.saved_collection_items sci
    join public.saved_places sp on sp.id = sci.saved_place_id
    where sci.collection_id = c.id
  ) items_summary on true
  where c.user_id = actor;

  return result;
end;
$$;

create or replace function public.fetch_collection_places(p_collection_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot view collection places';
  end if;
  if not exists (
    select 1 from public.saved_collections
    where id = p_collection_id and user_id = actor
  ) then
    raise exception using errcode = 'P0002', message = 'Collection not found';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'saved_place_id', sp.id,
      'target_type', case
        when sp.spot_id is not null then 'spot'
        when sp.restaurant_id is not null then 'restaurant'
        else 'external'
      end,
      'target_id', coalesce(sp.spot_id::text, sp.restaurant_id::text, sp.external_place_id),
      'external_provider', sp.external_provider,
      'name', coalesce(ps.name, pr.name),
      'state', coalesce(ps.state, pr.state),
      'city', coalesce(ps.city, pr.city),
      'category_or_cuisine', coalesce(ps.category, pr.cuisine_type),
      'price_range', coalesce(ps.price_range, pr.price_range),
      'image_url', coalesce(ps.image_path, pr.cover_image_path),
      'rating', coalesce(ps.rating_average, pr.rating_average),
      'review_count', coalesce(ps.review_count, pr.review_count),
      'added_at', sci.added_at
    ) order by sci.added_at desc
  ), '[]'::jsonb)
  into result
  from public.saved_collection_items sci
  join public.saved_places sp on sp.id = sci.saved_place_id and sp.user_id = actor
  left join public.published_spots ps on ps.id = sp.spot_id
  left join public.published_restaurants pr on pr.id = sp.restaurant_id
  where sci.collection_id = p_collection_id;

  return result;
end;
$$;

-- Keep the existing UUID overload for older app builds and internal callers.
-- The text overload below is additive and carries provider identity when the
-- target is external.
create function public.set_place_collections(
  p_target_type text,
  p_target_id text,
  p_collection_ids uuid[],
  p_external_provider text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  internal_id uuid;
  place_id uuid;
  cid uuid;
  valid_collection_count integer := 0;
  total_memberships integer := 0;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage saved collections';
  end if;

  if p_target_type in ('spot', 'restaurant') then
    begin
      internal_id := p_target_id::uuid;
    exception when invalid_text_representation then
      raise exception using errcode = '22023', message = 'Invalid saved-place target';
    end;
    if p_external_provider is not null then
      raise exception using errcode = '22023', message = 'Invalid external provider';
    end if;
    if p_target_type = 'spot'
        and not exists (select 1 from public.published_spots where id = internal_id) then
      raise exception using errcode = 'P0002', message = 'Spot is unavailable';
    end if;
    if p_target_type = 'restaurant'
        and not exists (select 1 from public.published_restaurants where id = internal_id) then
      raise exception using errcode = 'P0002', message = 'Restaurant is unavailable';
    end if;
  elsif p_target_type = 'external' then
    if p_external_provider <> 'google'
        or p_target_id !~ '^[A-Za-z0-9_-]{8,256}$' then
      raise exception using errcode = '22023', message = 'Unsupported external place';
    end if;
  else
    raise exception using errcode = '22023', message = 'Unsupported saved-place target';
  end if;

  if p_collection_ids is not null and cardinality(p_collection_ids) > 0 then
    select count(*) into valid_collection_count
    from public.saved_collections
    where user_id = actor and id = any(p_collection_ids);
    if valid_collection_count <> cardinality(p_collection_ids) then
      raise exception using errcode = '42501', message = 'One or more invalid or unauthorized collections';
    end if;
  end if;

  select id into place_id
  from public.saved_places
  where user_id = actor and (
    (p_target_type = 'spot' and spot_id = internal_id)
    or (p_target_type = 'restaurant' and restaurant_id = internal_id)
    or (p_target_type = 'external' and external_provider = p_external_provider
      and external_place_id = p_target_id)
  );

  if p_collection_ids is null or cardinality(p_collection_ids) = 0 then
    if place_id is not null then
      delete from public.saved_collection_items where saved_place_id = place_id;
      delete from public.saved_places where id = place_id and user_id = actor;
    end if;
    return jsonb_build_object(
      'target_type', p_target_type,
      'target_id', p_target_id,
      'external_provider', p_external_provider,
      'saved', false,
      'collection_ids', '[]'::jsonb
    );
  end if;

  if place_id is null then
    insert into public.saved_places (
      user_id, spot_id, restaurant_id, external_provider, external_place_id
    ) values (
      actor,
      case when p_target_type = 'spot' then internal_id end,
      case when p_target_type = 'restaurant' then internal_id end,
      case when p_target_type = 'external' then p_external_provider end,
      case when p_target_type = 'external' then p_target_id end
    ) returning id into place_id;
  end if;

  delete from public.saved_collection_items sci
  where sci.saved_place_id = place_id
    and exists (
      select 1 from public.saved_collections c
      where c.id = sci.collection_id and c.user_id = actor
    )
    and sci.collection_id <> all(p_collection_ids);

  foreach cid in array p_collection_ids loop
    insert into public.saved_collection_items(collection_id, saved_place_id)
    values (cid, place_id)
    on conflict do nothing;
  end loop;

  select count(*) into total_memberships
  from public.saved_collection_items
  where saved_place_id = place_id;

  update public.saved_collections
  set updated_at = clock_timestamp()
  where id = any(p_collection_ids) and user_id = actor;

  return jsonb_build_object(
    'target_type', p_target_type,
    'target_id', p_target_id,
    'external_provider', p_external_provider,
    'saved', total_memberships > 0,
    'collection_ids', to_jsonb(p_collection_ids)
  );
end;
$$;

revoke all on function public.set_place_collections(text, text, uuid[], text)
  from public, anon;
grant execute on function public.set_place_collections(text, text, uuid[], text)
  to authenticated;

create function public.list_place_collection_ids(
  p_target_type text,
  p_target_id text,
  p_external_provider text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  internal_id uuid;
  result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot view saved collections';
  end if;
  if p_target_type in ('spot', 'restaurant') then
    begin
      internal_id := p_target_id::uuid;
    exception when invalid_text_representation then
      raise exception using errcode = '22023', message = 'Invalid saved-place target';
    end;
  elsif p_target_type <> 'external'
      or p_external_provider <> 'google'
      or p_target_id !~ '^[A-Za-z0-9_-]{8,256}$' then
    raise exception using errcode = '22023', message = 'Unsupported saved-place target';
  end if;

  select coalesce(jsonb_agg(sci.collection_id), '[]'::jsonb)
  into result
  from public.saved_collection_items sci
  join public.saved_collections c
    on c.id = sci.collection_id and c.user_id = actor
  join public.saved_places sp
    on sp.id = sci.saved_place_id and sp.user_id = actor
  where (p_target_type = 'spot' and sp.spot_id = internal_id)
    or (p_target_type = 'restaurant' and sp.restaurant_id = internal_id)
    or (p_target_type = 'external'
      and sp.external_provider = p_external_provider
      and sp.external_place_id = p_target_id);

  return result;
end;
$$;

revoke all on function public.list_place_collection_ids(text, text, text)
  from public, anon;
grant execute on function public.list_place_collection_ids(text, text, text)
  to authenticated;

create or replace function public.fetch_saved_route_candidates(
  p_collection_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot generate saved routes';
  end if;
  if p_collection_id is not null and not exists (
    select 1 from public.saved_collections
    where id = p_collection_id and user_id = actor
  ) then
    raise exception using errcode = 'P0002', message = 'Collection not found';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'saved_place_id', sp.id,
      'target_type', case
        when sp.spot_id is not null then 'spot'
        when sp.restaurant_id is not null then 'restaurant'
        else 'external'
      end,
      'target_id', coalesce(sp.spot_id::text, sp.restaurant_id::text, sp.external_place_id),
      'external_provider', sp.external_provider,
      'name', coalesce(ps.name, pr.name),
      'state', coalesce(ps.state, pr.state),
      'city', coalesce(ps.city, pr.city),
      'latitude', coalesce(ps.latitude, pr.latitude),
      'longitude', coalesce(ps.longitude, pr.longitude),
      'category_or_cuisine', coalesce(ps.category, pr.cuisine_type),
      'best_time', ps.best_time,
      'things_to_do', ps.things_to_do,
      'reviewed_dishes', pr.reviewed_dishes,
      'price_range', coalesce(ps.price_range, pr.price_range),
      'image_url', coalesce(ps.image_path, pr.cover_image_path),
      'rating', coalesce(ps.rating_average, pr.rating_average),
      'review_count', coalesce(ps.review_count, pr.review_count)
    ) order by coalesce(sci.added_at, sp.saved_at) desc
  ), '[]'::jsonb)
  into result
  from public.saved_places sp
  left join lateral (
    select max(item.added_at) as added_at
    from public.saved_collection_items item
    where item.saved_place_id = sp.id
      and item.collection_id = p_collection_id
  ) sci on p_collection_id is not null
  left join public.published_spots ps on ps.id = sp.spot_id
  left join public.published_restaurants pr on pr.id = sp.restaurant_id
  where sp.user_id = actor
    and (p_collection_id is null or sci.added_at is not null)
    and (ps.id is not null or pr.id is not null or sp.external_place_id is not null);

  return result;
end;
$$;

create or replace function private.validate_itinerary_targets(
  p_user_id uuid,
  p_ordered_targets jsonb
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_count integer;
  distinct_count integer;
  valid_count integer;
begin
  if jsonb_typeof(p_ordered_targets) <> 'array' then
    raise exception using errcode = '22023', message = 'Itinerary targets must be an array';
  end if;
  target_count := jsonb_array_length(p_ordered_targets);
  if target_count < 1 or target_count > 50 then
    raise exception using errcode = '22023', message = 'An itinerary requires 1 to 50 stops';
  end if;

  select count(distinct (item->>'type', item->>'id', coalesce(item->>'provider', '')))
  into distinct_count
  from jsonb_array_elements(p_ordered_targets) item;
  if distinct_count <> target_count then
    raise exception using errcode = '23505', message = 'Itinerary stops must be unique';
  end if;

  select count(*) into valid_count
  from jsonb_array_elements(p_ordered_targets) item
  where (
    item->>'type' = 'spot'
    and (item->>'id') ~* '^[0-9a-f-]{36}$'
    and exists (
      select 1 from public.saved_places saved
      join public.published_spots published on published.id = saved.spot_id
      where saved.user_id = p_user_id and saved.spot_id = (item->>'id')::uuid
    )
  ) or (
    item->>'type' = 'restaurant'
    and (item->>'id') ~* '^[0-9a-f-]{36}$'
    and exists (
      select 1 from public.saved_places saved
      join public.published_restaurants published on published.id = saved.restaurant_id
      where saved.user_id = p_user_id and saved.restaurant_id = (item->>'id')::uuid
    )
  ) or (
    item->>'type' = 'external'
    and item->>'provider' = 'google'
    and (item->>'id') ~ '^[A-Za-z0-9_-]{8,256}$'
    and exists (
      select 1 from public.saved_places saved
      where saved.user_id = p_user_id
        and saved.external_provider = item->>'provider'
        and saved.external_place_id = item->>'id'
    )
  );
  if valid_count <> target_count then
    raise exception using errcode = '42501', message = 'Itinerary contains an unavailable or unsaved target';
  end if;
end;
$$;

create or replace function private.insert_itinerary_items(
  p_itinerary_id uuid,
  p_ordered_targets jsonb
)
returns void
language sql
security definer
set search_path = pg_catalog, public
as $$
  insert into public.itinerary_items (
    itinerary_id, position, spot_id, restaurant_id,
    external_provider, external_place_id
  )
  select
    p_itinerary_id,
    item.ordinality::integer,
    case when item.value->>'type' = 'spot'
      then (item.value->>'id')::uuid end,
    case when item.value->>'type' = 'restaurant'
      then (item.value->>'id')::uuid end,
    case when item.value->>'type' = 'external'
      then item.value->>'provider' end,
    case when item.value->>'type' = 'external'
      then item.value->>'id' end
  from jsonb_array_elements(p_ordered_targets) with ordinality item(value, ordinality);
$$;

revoke all on function private.validate_itinerary_targets(uuid, jsonb)
  from public;
revoke all on function private.insert_itinerary_items(uuid, jsonb)
  from public;

-- Restaurant submissions may cite a supported public source. Creator-profile
-- validation still passes an explicit platform and remains social-only.
create or replace function private.is_supported_social_url(
  p_url text,
  p_platform text default null
)
returns boolean
language sql
immutable
set search_path = pg_catalog
as $$
  select case
    when p_platform = 'tiktok' then
      p_url ~* '^https://(www[.])?tiktok[.]com(/|$)'
    when p_platform = 'instagram' then
      p_url ~* '^https://(www[.])?instagram[.]com(/|$)'
    when p_platform is null then
      char_length(p_url) <= 2048
      and p_url ~* '^https://[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:[.][A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+(?:/|[?#]|$)'
      and p_url !~* '^https://[^/]*(instagram[.]com[.]|tiktok[.]com[.]|google[.]com[.])'
    else false
  end;
$$;

revoke all on function private.is_supported_social_url(text, text)
  from public, anon, authenticated, service_role;

alter table public.restaurant_revisions
  drop constraint if exists restaurant_social_url_review_post,
  drop constraint if exists restaurant_social_url_supported,
  drop constraint if exists restaurant_source_url_supported,
  add constraint restaurant_source_url_supported check (
    private.is_supported_social_url(social_media_url, null)
  );

alter table public.restaurant_revisions
  drop constraint if exists restaurant_revisions_ai_source_platform_check,
  drop constraint if exists restaurant_revisions_ai_provenance_check,
  add constraint restaurant_revisions_ai_source_platform_check check (
    ai_source_platform is null
    or ai_source_platform in ('instagram', 'tiktok', 'google_maps', 'website')
  ),
  add constraint restaurant_revisions_ai_provenance_check check (
    (ai_assisted = true and ai_source_platform is not null)
    or (ai_assisted = false and ai_source_platform is null)
  );

alter table public.ai_generation_usage
  drop constraint if exists ai_generation_usage_platform_check,
  add constraint ai_generation_usage_platform_check check (
    platform in ('instagram', 'tiktok', 'google_maps', 'website')
  );

-- The table constraints are not the only provenance gate: both Creator draft
-- RPCs validate the platform before writing. Replace their current definitions
-- so a Maps/website AI draft can actually complete the existing form workflow.
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
      message = 'Unsupported source URL';
  end if;
  if p_cover_image_path is not null
      and p_cover_image_path !~ (
        '^' || auth.uid()::text || '/[A-Za-z0-9_-]+\.(jpg|png|webp)$'
      ) then
    raise exception using errcode = '22023',
      message = 'Invalid restaurant image path';
  end if;

  if coalesce(p_ai_assisted, false) = true then
    if p_ai_source_platform is null
        or p_ai_source_platform not in (
          'instagram', 'tiktok', 'google_maps', 'website'
        ) then
      raise exception using errcode = '22023',
        message = 'Valid AI source platform required when AI-assisted';
    end if;
  elsif p_ai_source_platform is not null then
    raise exception using errcode = '22023',
      message = 'AI source platform must be null when not AI-assisted';
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
    p_latitude, p_longitude, coalesce(p_ai_assisted, false),
    p_ai_source_platform
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
  p_cover_image_path text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
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
    raise exception using errcode = '42501',
      message = 'Approved creator role required';
  end if;
  if not private.is_supported_social_url(p_social_media_url, null) then
    raise exception using errcode = '22023',
      message = 'Unsupported source URL';
  end if;

  if coalesce(p_ai_assisted, false) = true then
    if p_ai_source_platform is null
        or p_ai_source_platform not in (
          'instagram', 'tiktok', 'google_maps', 'website'
        ) then
      raise exception using errcode = '22023',
        message = 'Valid AI source platform required when AI-assisted';
    end if;
  elsif p_ai_source_platform is not null then
    raise exception using errcode = '22023',
      message = 'AI source platform must be null when not AI-assisted';
  end if;

  select * into entity
  from public.restaurants
  where owner_id = auth.uid()
    and current_revision_id = p_source_revision_id
    and ownership_status = 'creator_owned'
  for update;
  if not found then
    raise exception using errcode = 'P0002',
      message = 'Current owned restaurant revision not found';
  end if;

  select * into source
  from public.restaurant_revisions
  where id = p_source_revision_id
  for update;
  if source.status not in (
    'draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn'
  ) then
    raise exception using errcode = '22023',
      message = 'Restaurant revision cannot be edited';
  end if;

  selected_image_path := coalesce(p_cover_image_path, source.cover_image_path);
  if selected_image_path is null
      or selected_image_path !~ (
        '^' || auth.uid()::text || '/[A-Za-z0-9_-]+\.(jpg|png|webp)$'
      )
      or not exists (
        select 1 from storage.objects object
        where object.bucket_id = 'restaurant-images'
          and object.name = selected_image_path
      ) then
    raise exception using errcode = '22023',
      message = 'Valid restaurant image required';
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
      cover_image_path, latitude, longitude, status,
      ai_assisted, ai_source_platform
    ) values (
      entity.id, next_number, auth.uid(), btrim(p_name), btrim(p_address),
      btrim(p_state), btrim(p_city), btrim(p_cuisine_type), p_price_range,
      btrim(p_reviewed_dishes), btrim(p_social_media_url), selected_image_path,
      p_latitude, p_longitude, 'draft',
      coalesce(p_ai_assisted, false), p_ai_source_platform
    ) returning * into saved;

    update public.restaurants
    set current_revision_id = saved.id
    where id = entity.id;
  end if;

  return jsonb_build_object(
    'restaurant_id', entity.id,
    'revision_id', saved.id,
    'status', saved.status,
    'revision_number', saved.revision_number
  );
end;
$$;

commit;
