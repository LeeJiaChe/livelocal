-- Migration: 202608210002_saved_collections_hardening.sql
-- Description: Enforce DB ownership invariants on collection items, return user_id, support cover image metadata, description clearing, and independent collection places RPC.

begin;

-- 1. DB-Level Ownership Invariant Trigger
create or replace function public.check_saved_collection_item_ownership()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_collection_user_id uuid;
  v_place_user_id uuid;
begin
  select user_id into v_collection_user_id
  from public.saved_collections
  where id = new.collection_id;

  if v_collection_user_id is null then
    raise exception using errcode = '23503', message = 'Collection does not exist';
  end if;

  select user_id into v_place_user_id
  from public.saved_places
  where id = new.saved_place_id;

  if v_place_user_id is null then
    raise exception using errcode = '23503', message = 'Saved place does not exist';
  end if;

  if v_collection_user_id <> v_place_user_id then
    raise exception using errcode = '42501', message = 'Cannot add place owned by another user to this collection';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_saved_collection_items_ownership on public.saved_collection_items;
create trigger trg_saved_collection_items_ownership
  before insert or update on public.saved_collection_items
  for each row
  execute function public.check_saved_collection_item_ownership();

-- 2. Update create_saved_collection to return user_id
create or replace function public.create_saved_collection(
  p_name text,
  p_description text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  trimmed_name text := btrim(coalesce(p_name, ''));
  trimmed_desc text := nullif(btrim(coalesce(p_description, '')), '');
  created public.saved_collections;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage saved collections';
  end if;

  if char_length(trimmed_name) not between 1 and 80 then
    raise exception using errcode = '22023', message = 'Collection name must be between 1 and 80 characters';
  end if;

  if trimmed_desc is not null and char_length(trimmed_desc) > 300 then
    raise exception using errcode = '22023', message = 'Description must not exceed 300 characters';
  end if;

  insert into public.saved_collections (user_id, name, description)
  values (actor, trimmed_name, trimmed_desc)
  returning * into created;

  return jsonb_build_object(
    'id', created.id,
    'user_id', created.user_id,
    'name', created.name,
    'description', created.description,
    'created_at', created.created_at,
    'updated_at', created.updated_at
  );
exception
  when unique_violation then
    raise exception using errcode = '23505', message = 'A collection with this name already exists';
end;
$$;

-- 3. Update rename_saved_collection to return user_id and allow clearing description
create or replace function public.rename_saved_collection(
  p_collection_id uuid,
  p_name text,
  p_description text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  trimmed_name text := btrim(coalesce(p_name, ''));
  trimmed_desc text := nullif(btrim(coalesce(p_description, '')), '');
  updated public.saved_collections;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage saved collections';
  end if;

  if char_length(trimmed_name) not between 1 and 80 then
    raise exception using errcode = '22023', message = 'Collection name must be between 1 and 80 characters';
  end if;

  if trimmed_desc is not null and char_length(trimmed_desc) > 300 then
    raise exception using errcode = '22023', message = 'Description must not exceed 300 characters';
  end if;

  update public.saved_collections
  set name = trimmed_name,
      description = case when p_description is not null then trimmed_desc else description end,
      updated_at = clock_timestamp()
  where id = p_collection_id and user_id = actor
  returning * into updated;

  if not found then
    raise exception using errcode = 'P0002', message = 'Collection not found';
  end if;

  return jsonb_build_object(
    'id', updated.id,
    'user_id', updated.user_id,
    'name', updated.name,
    'description', updated.description,
    'created_at', updated.created_at,
    'updated_at', updated.updated_at
  );
exception
  when unique_violation then
    raise exception using errcode = '23505', message = 'A collection with this name already exists';
end;
$$;

-- 4. Update list_my_saved_collections with user_id and cover image details
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
      (
        select case when sp_sub.spot_id is not null then 'spot' else 'restaurant' end
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

-- 5. RPC: fetch_collection_places (Fetches resolved place metadata directly from collection)
create or replace function public.fetch_collection_places(
  p_collection_id uuid
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
    raise exception using errcode = '42501', message = 'Account cannot view collection places';
  end if;

  if not exists (select 1 from public.saved_collections where id = p_collection_id and user_id = actor) then
    raise exception using errcode = 'P0002', message = 'Collection not found';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'saved_place_id', sp.id,
      'target_type', case when sp.spot_id is not null then 'spot' else 'restaurant' end,
      'target_id', coalesce(sp.spot_id, sp.restaurant_id),
      'name', coalesce(ps.name, pr.name, 'Unavailable place'),
      'state', coalesce(ps.state, pr.state, ''),
      'city', coalesce(ps.city, pr.city, ''),
      'category_or_cuisine', coalesce(ps.category, pr.cuisine_type, ''),
      'price_range', pr.price_range,
      'image_url', coalesce(ps.image_path, pr.cover_image_path),
      'rating', coalesce(ps.rating, pr.rating, 0.0),
      'review_count', coalesce(ps.review_count, pr.review_count, 0),
      'added_at', sci.added_at
    ) order by sci.added_at desc
  ), '[]'::jsonb)
  into result
  from public.saved_collection_items sci
  join public.saved_places sp on sp.id = sci.saved_place_id
  left join public.published_spots ps on ps.id = sp.spot_id
  left join public.published_restaurants pr on pr.id = sp.restaurant_id
  where sci.collection_id = p_collection_id;

  return result;
end;
$$;

-- 6. Permissions & Grants
revoke all on function public.fetch_collection_places(uuid) from public;
grant execute on function public.fetch_collection_places(uuid) to authenticated;

revoke all on table public.saved_collections from anon, authenticated;
revoke all on table public.saved_collection_items from anon, authenticated;
grant select on table public.saved_collections to authenticated;
grant select on table public.saved_collection_items to authenticated;

commit;
