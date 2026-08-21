-- Migration: 202608210001_saved_collections_schema.sql
-- Description: Real user-owned Saved Collections (Airbnb-style) with multi-collection support, RLS, RPCs, and idempotent backfill.

begin;

-- 1. Create saved_collections table
create table if not exists public.saved_collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  description text check (description is null or char_length(description) <= 300),
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp()
);

create unique index if not exists saved_collections_user_name_unique
  on public.saved_collections(user_id, lower(btrim(name)));

create index if not exists saved_collections_user_updated
  on public.saved_collections(user_id, updated_at desc);

-- 2. Create saved_collection_items table
create table if not exists public.saved_collection_items (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references public.saved_collections(id) on delete cascade,
  saved_place_id uuid not null references public.saved_places(id) on delete cascade,
  added_at timestamptz not null default clock_timestamp(),
  constraint saved_collection_items_unique unique (collection_id, saved_place_id)
);

create index if not exists saved_collection_items_collection_idx
  on public.saved_collection_items(collection_id, added_at desc);

create index if not exists saved_collection_items_place_idx
  on public.saved_collection_items(saved_place_id);

-- 3. Enable RLS
alter table public.saved_collections enable row level security;
alter table public.saved_collection_items enable row level security;

-- Drop existing policies if any to ensure clean idempotent creation
drop policy if exists saved_collections_owner_select on public.saved_collections;
drop policy if exists saved_collection_items_owner_select on public.saved_collection_items;

create policy saved_collections_owner_select on public.saved_collections
  for select to authenticated
  using (user_id = auth.uid() and private.can_use_protected_features());

create policy saved_collection_items_owner_select on public.saved_collection_items
  for select to authenticated
  using (exists (
    select 1 from public.saved_collections c
    where c.id = public.saved_collection_items.collection_id
      and c.user_id = auth.uid()
      and private.can_use_protected_features()
  ));

revoke all on table public.saved_collections from anon, authenticated;
revoke all on table public.saved_collection_items from anon, authenticated;
grant select on table public.saved_collections to authenticated;
grant select on table public.saved_collection_items to authenticated;

-- 4. RPC: create_saved_collection
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

-- 5. RPC: rename_saved_collection
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
      description = coalesce(trimmed_desc, description),
      updated_at = clock_timestamp()
  where id = p_collection_id and user_id = actor
  returning * into updated;

  if not found then
    raise exception using errcode = 'P0002', message = 'Collection not found';
  end if;

  return jsonb_build_object(
    'id', updated.id,
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

-- 6. RPC: delete_saved_collection
create or replace function public.delete_saved_collection(
  p_collection_id uuid
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  orphaned_place_ids uuid[];
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage saved collections';
  end if;

  -- Find saved_places that belong to this collection and will have 0 memberships after deletion
  select array_agg(sp.id) into orphaned_place_ids
  from public.saved_collection_items sci
  join public.saved_places sp on sp.id = sci.saved_place_id
  where sci.collection_id = p_collection_id
    and sp.user_id = actor
    and not exists (
      select 1 from public.saved_collection_items other_sci
      where other_sci.saved_place_id = sp.id
        and other_sci.collection_id <> p_collection_id
    );

  delete from public.saved_collections
  where id = p_collection_id and user_id = actor;

  if not found then
    raise exception using errcode = 'P0002', message = 'Collection not found';
  end if;

  -- Clean up orphaned saved_places so bookmark state reflects unsaved
  if orphaned_place_ids is not null and array_length(orphaned_place_ids, 1) > 0 then
    delete from public.saved_places
    where id = any(orphaned_place_ids) and user_id = actor;
  end if;
end;
$$;

-- 7. RPC: set_place_collections (Add/remove place to/from specified collections)
create or replace function public.set_place_collections(
  p_target_type text,
  p_target_id uuid,
  p_collection_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  place_id uuid;
  cid uuid;
  valid_collection_count integer := 0;
  total_memberships integer := 0;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage saved collections';
  end if;

  if p_target_type = 'spot' then
    if not exists (select 1 from public.published_spots where id = p_target_id) then
      raise exception using errcode = 'P0002', message = 'Spot is unavailable';
    end if;
  elsif p_target_type = 'restaurant' then
    if not exists (select 1 from public.published_restaurants where id = p_target_id) then
      raise exception using errcode = 'P0002', message = 'Restaurant is unavailable';
    end if;
  else
    raise exception using errcode = '22023', message = 'Unsupported saved-place target';
  end if;

  -- Verify all requested collection_ids belong to the current user
  if p_collection_ids is not null and array_length(p_collection_ids, 1) > 0 then
    select count(*) into valid_collection_count
    from public.saved_collections
    where user_id = actor and id = any(p_collection_ids);

    if valid_collection_count <> array_length(p_collection_ids, 1) then
      raise exception using errcode = '42501', message = 'One or more invalid or unauthorized collections';
    end if;
  end if;

  -- If collection_ids is empty, remove all memberships and the saved_place row
  if p_collection_ids is null or array_length(p_collection_ids, 1) = 0 then
    -- Find existing saved_place
    select id into place_id
    from public.saved_places
    where user_id = actor
      and (
        (p_target_type = 'spot' and spot_id = p_target_id)
        or (p_target_type = 'restaurant' and restaurant_id = p_target_id)
      );

    if place_id is not null then
      delete from public.saved_collection_items where saved_place_id = place_id;
      delete from public.saved_places where id = place_id;
    end if;

    return jsonb_build_object(
      'target_type', p_target_type,
      'target_id', p_target_id,
      'saved', false,
      'collection_ids', '[]'::jsonb
    );
  end if;

  -- Otherwise, ensure saved_places row exists
  insert into public.saved_places (user_id, spot_id, restaurant_id)
  values (
    actor,
    case when p_target_type = 'spot' then p_target_id else null end,
    case when p_target_type = 'restaurant' then p_target_id else null end
  )
  on conflict do nothing;

  select id into place_id
  from public.saved_places
  where user_id = actor
    and (
      (p_target_type = 'spot' and spot_id = p_target_id)
      or (p_target_type = 'restaurant' and restaurant_id = p_target_id)
    );

  -- Remove memberships from user collections NOT in p_collection_ids
  delete from public.saved_collection_items sci
  where sci.saved_place_id = place_id
    and exists (
      select 1 from public.saved_collections c
      where c.id = sci.collection_id and c.user_id = actor
    )
    and sci.collection_id <> all(p_collection_ids);

  -- Insert memberships for collections in p_collection_ids
  foreach cid in array p_collection_ids loop
    insert into public.saved_collection_items (collection_id, saved_place_id)
    values (cid, place_id)
    on conflict do nothing;
  end loop;

  select count(*) into total_memberships
  from public.saved_collection_items sci
  where sci.saved_place_id = place_id;

  return jsonb_build_object(
    'target_type', p_target_type,
    'target_id', p_target_id,
    'saved', total_memberships > 0,
    'collection_ids', to_jsonb(p_collection_ids)
  );
end;
$$;

-- 8. RPC: list_my_saved_collections (With item counts and cover photos)
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
      'name', c.name,
      'description', c.description,
      'created_at', c.created_at,
      'updated_at', c.updated_at,
      'item_count', coalesce(items_summary.total_items, 0),
      'spot_count', coalesce(items_summary.total_spots, 0),
      'restaurant_count', coalesce(items_summary.total_restaurants, 0),
      'cover_image_url', items_summary.sample_image_url
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

-- 9. Grants on RPCs
revoke all on function public.create_saved_collection(text, text) from public;
revoke all on function public.rename_saved_collection(uuid, text, text) from public;
revoke all on function public.delete_saved_collection(uuid) from public;
revoke all on function public.set_place_collections(text, uuid, uuid[]) from public;
revoke all on function public.list_my_saved_collections() from public;

grant execute on function public.create_saved_collection(text, text) to authenticated;
grant execute on function public.rename_saved_collection(uuid, text, text) to authenticated;
grant execute on function public.delete_saved_collection(uuid) to authenticated;
grant execute on function public.set_place_collections(text, uuid, uuid[]) to authenticated;
grant execute on function public.list_my_saved_collections() to authenticated;

-- 10. Idempotent Backfill: For existing users with saved_places, ensure a 'Saved places' collection exists and attach places
do $$
declare
  r record;
  default_coll_id uuid;
begin
  for r in (select distinct user_id from public.saved_places) loop
    -- Check if user already has a 'Saved places' collection
    select id into default_coll_id
    from public.saved_collections
    where user_id = r.user_id and lower(btrim(name)) = 'saved places';

    if default_coll_id is null then
      insert into public.saved_collections (user_id, name, description)
      values (r.user_id, 'Saved places', 'Default collection for saved places')
      returning id into default_coll_id;
    end if;

    -- Attach existing saved_places to the default collection
    insert into public.saved_collection_items (collection_id, saved_place_id)
    select default_coll_id, sp.id
    from public.saved_places sp
    where sp.user_id = r.user_id
    on conflict (collection_id, saved_place_id) do nothing;
  end loop;
end;
$$;

commit;
