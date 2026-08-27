begin;

create extension if not exists pgtap with schema extensions;
select plan(16);

-- 1. Table privilege tests
select is(
  has_table_privilege('authenticated', 'public.user_blocks', 'SELECT'),
  false,
  'authenticated role does NOT have SELECT privilege on public.user_blocks'
);

select is(
  has_table_privilege('anon', 'public.user_blocks', 'SELECT'),
  false,
  'anon role does NOT have SELECT privilege on public.user_blocks'
);

select is(
  has_table_privilege('authenticated', 'public.user_blocks', 'INSERT'),
  false,
  'authenticated role does NOT have INSERT privilege on public.user_blocks'
);

select is(
  has_table_privilege('authenticated', 'public.user_blocks', 'UPDATE'),
  false,
  'authenticated role does NOT have UPDATE privilege on public.user_blocks'
);

select is(
  has_table_privilege('authenticated', 'public.user_blocks', 'DELETE'),
  false,
  'authenticated role does NOT have DELETE privilege on public.user_blocks'
);

-- 2. Function execution privileges
select is(
  has_function_privilege('authenticated', 'public.block_content_author(text, uuid)', 'EXECUTE'),
  true,
  'authenticated role CAN execute block_content_author'
);

select is(
  has_function_privilege('anon', 'public.block_content_author(text, uuid)', 'EXECUTE'),
  false,
  'anon role CANNOT execute block_content_author'
);

select is(
  has_function_privilege('authenticated', 'public.list_my_blocked_users()', 'EXECUTE'),
  true,
  'authenticated role CAN execute list_my_blocked_users'
);

select is(
  has_function_privilege('anon', 'public.list_my_blocked_users()', 'EXECUTE'),
  false,
  'anon role CANNOT execute list_my_blocked_users'
);

select is(
  has_function_privilege('authenticated', 'public.unblock_user(uuid)', 'EXECUTE'),
  true,
  'authenticated role CAN execute unblock_user'
);

select is(
  has_function_privilege('anon', 'public.unblock_user(uuid)', 'EXECUTE'),
  false,
  'anon role CANNOT execute unblock_user'
);

-- 3. Behavioral test with test users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '95000000-0000-0000-0000-000000000001', 'authenticated',
    'authenticated', 'hardening-author@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Hidden Author"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '95000000-0000-0000-0000-000000000002', 'authenticated',
    'authenticated', 'hardening-blocker@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Hardening Blocker"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

insert into public.spots (id, owner_id)
values ('96000000-0000-0000-0000-000000000001', '95000000-0000-0000-0000-000000000001');

insert into public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category,
  description, state, city, address, price_range, best_time, things_to_do,
  submitted_at, decided_at
)
values (
  '97000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-000000000001',
  1,
  '95000000-0000-0000-0000-000000000001',
  'approved',
  'Hardening Test Spot',
  'Attraction',
  'Spot for testing user blocks hardening',
  'Penang',
  'George Town',
  'Chulia St',
  '$',
  'Morning',
  array['Walking'],
  clock_timestamp(),
  clock_timestamp()
);

update public.spots set
  current_revision_id = '97000000-0000-0000-0000-000000000001',
  approved_revision_id = '97000000-0000-0000-0000-000000000001'
where id = '96000000-0000-0000-0000-000000000001';

insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
)
select spot_id, id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
from public.spot_revisions
where id = '97000000-0000-0000-0000-000000000001';

-- Author creates anonymous review
select set_config('request.jwt.claim.sub', '95000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select public.accept_current_ugc_rules();

select public.upsert_review_with_photos(
  'spot',
  '96000000-0000-0000-0000-000000000001',
  5,
  'Review by hidden author',
  null,
  '{}'::text[],
  '98000000-0000-0000-0000-000000000001',
  true
);

-- Switch to blocker
select set_config('request.jwt.claim.sub', '95000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- Block anonymous review
select public.block_content_author('review', '98000000-0000-0000-0000-000000000001');

-- Check 12: list_my_blocked_users returns generic display name
select is(
  (select public.list_my_blocked_users()->0->>'display_name'),
  'Anonymous reviewer',
  'list_my_blocked_users returns generic Anonymous reviewer'
);

-- Check 13: list_my_blocked_users does not leak real author UUID
select isnt(
  (select public.list_my_blocked_users()->0->>'user_id'),
  '95000000-0000-0000-0000-000000000001',
  'list_my_blocked_users does not expose real author UUID'
);

-- Check 14: RLS content filtering still functions
set local role authenticated;
select is(
  (select count(*)::int from public.public_reviews where id = '98000000-0000-0000-0000-000000000001'),
  0,
  'Blocked anonymous review is hidden from blocker by RLS'
);

-- Check 15: unblock using opaque id removes block
select public.unblock_user(
  (select (public.list_my_blocked_users()->0->>'user_id')::uuid)
);

select is(
  (select jsonb_array_length(public.list_my_blocked_users())),
  0,
  'Unblock with opaque ID clears blocked list'
);

-- Check 16: Review is visible again after unblock
select is(
  (select count(*)::int from public.public_reviews where id = '98000000-0000-0000-0000-000000000001'),
  1,
  'Review is visible again after unblocking'
);

select * from finish();
rollback;
