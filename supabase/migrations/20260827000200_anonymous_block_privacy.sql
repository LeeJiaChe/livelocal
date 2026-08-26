begin;

-- 1. Add privacy-safe opaque block identifier and identity_hidden flag to public.user_blocks
alter table public.user_blocks
  add column if not exists id uuid not null default gen_random_uuid(),
  add column if not exists identity_hidden boolean not null default false;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_blocks_id_key'
      and conrelid = 'public.user_blocks'::regclass
  ) then
    alter table public.user_blocks add constraint user_blocks_id_key unique (id);
  end if;
end $$;

-- 2. Update public.block_content_author to prevent deanonymization
create or replace function public.block_content_author(
  p_target_type text,
  p_target_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  target_author uuid;
  target_name text;
  target_is_anon boolean := false;
  block_row public.user_blocks%rowtype;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot block users';
  end if;

  if p_target_type = 'review' then
    select review.user_id, coalesce(review.is_anonymous, false)
    into target_author, target_is_anon
    from public.reviews review
    join public.public_reviews projection on projection.id = review.id
    where review.id = p_target_id;
  elsif p_target_type = 'spot' then
    select spot.owner_id into target_author
    from public.spots spot
    join public.published_spots projection on projection.id = spot.id
    where spot.id = p_target_id;
  elsif p_target_type = 'restaurant' then
    select restaurant.owner_id into target_author
    from public.restaurants restaurant
    join public.published_restaurants projection on projection.id = restaurant.id
    where restaurant.id = p_target_id;
  else
    raise exception using errcode = '22023', message = 'Unsupported block target';
  end if;

  if target_author is null then
    raise exception using
      errcode = 'P0002',
      message = 'No account can be blocked for this content';
  end if;
  if target_author = auth.uid() then
    raise exception using errcode = '22023', message = 'Users cannot block themselves';
  end if;

  -- Insert or update the block row.
  -- Privacy rule: Once a block relationship is identity_hidden, it stays identity_hidden.
  insert into public.user_blocks (blocker_id, blocked_user_id, identity_hidden)
  values (auth.uid(), target_author, target_is_anon)
  on conflict (blocker_id, blocked_user_id) do update
    set identity_hidden = public.user_blocks.identity_hidden or excluded.identity_hidden
  returning * into block_row;

  if block_row.identity_hidden then
    return jsonb_build_object(
      'blocked_user_id', block_row.id,
      'display_name', 'Anonymous reviewer'
    );
  else
    select profile.display_name into target_name
    from public.profiles profile where profile.id = target_author;

    return jsonb_build_object(
      'blocked_user_id', target_author,
      'display_name', coalesce(target_name, 'Blocked user')
    );
  end if;
end;
$$;

-- 3. Update public.list_my_blocked_users to prevent deanonymization
create or replace function public.list_my_blocked_users()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'user_id', case
      when user_block.identity_hidden then user_block.id
      else user_block.blocked_user_id
    end,
    'display_name', case
      when user_block.identity_hidden then 'Anonymous reviewer'
      else coalesce(profile.display_name, 'Blocked user')
    end,
    'blocked_at', user_block.created_at
  ) order by user_block.created_at desc), '[]'::jsonb)
  from public.user_blocks user_block
  left join public.profiles profile on (
    profile.id = user_block.blocked_user_id
    and not user_block.identity_hidden
  )
  where user_block.blocker_id = auth.uid();
$$;

-- 4. Update public.unblock_user to accept either blocked_user_id or opaque user_blocks.id
create or replace function public.unblock_user(p_blocked_user_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage blocks';
  end if;

  delete from public.user_blocks
  where blocker_id = auth.uid()
    and (blocked_user_id = p_blocked_user_id or id = p_blocked_user_id);
end;
$$;

-- 5. Revoke and grant explicit permissions
revoke all on function public.block_content_author(text, uuid) from public;
revoke all on function public.unblock_user(uuid) from public;
revoke all on function public.list_my_blocked_users() from public;

grant execute on function public.block_content_author(text, uuid) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;
grant execute on function public.list_my_blocked_users() to authenticated;

commit;
