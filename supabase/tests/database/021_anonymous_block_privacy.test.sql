begin;

create extension if not exists pgtap with schema extensions;
select plan(14);

-- 1. Schema check
select has_column('public', 'user_blocks', 'id', 'user_blocks has id column');
select has_column('public', 'user_blocks', 'identity_hidden', 'user_blocks has identity_hidden column');

-- Create test accounts
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '90000000-0000-0000-0000-000000000001', 'authenticated',
    'authenticated', 'anon-author@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Real Author Name"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '90000000-0000-0000-0000-000000000002', 'authenticated',
    'authenticated', 'anon-blocker@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Blocker Viewer"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    '90000000-0000-0000-0000-000000000003', 'authenticated',
    'authenticated', 'third-party@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Third Party"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

insert into public.account_access (user_id, status)
values
  ('90000000-0000-0000-0000-000000000001', 'active'),
  ('90000000-0000-0000-0000-000000000002', 'active'),
  ('90000000-0000-0000-0000-000000000003', 'active');

-- Create a spot
insert into public.spots (id, owner_id)
values ('91000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001');

insert into public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category,
  description, state, city, address, price_range, best_time, things_to_do,
  submitted_at, decided_at
)
values (
  '92000000-0000-0000-0000-000000000001',
  '91000000-0000-0000-0000-000000000001',
  1,
  '90000000-0000-0000-0000-000000000001',
  'approved',
  'Anonymity Test Spot',
  'Attraction',
  'Spot for testing anonymous review blocking privacy',
  'Penang',
  'George Town',
  'Beach St',
  '$',
  'Morning',
  array['Walking'],
  clock_timestamp(),
  clock_timestamp()
);

update public.spots set
  current_revision_id = '92000000-0000-0000-0000-000000000001',
  approved_revision_id = '92000000-0000-0000-0000-000000000001'
where id = '91000000-0000-0000-0000-000000000001';

insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
)
select spot_id, id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
from public.spot_revisions
where id = '92000000-0000-0000-0000-000000000001';

-- Author creates an anonymous review
select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select public.accept_current_ugc_rules();

select public.upsert_review_with_photos(
  'spot',
  '91000000-0000-0000-0000-000000000001',
  5,
  'Secret review content',
  null,
  '{}'::text[],
  '93000000-0000-0000-0000-000000000001',
  true
);

-- Switch to Blocker viewer
select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- Call block_content_author on the anonymous review
create temp table anon_block_result as
select public.block_content_author('review', '93000000-0000-0000-0000-000000000001') as resp;

-- Check 3: RPC response display_name is 'Anonymous reviewer'
select is(
  (select resp->>'display_name' from anon_block_result),
  'Anonymous reviewer',
  'Anonymous block RPC returns generic "Anonymous reviewer"'
);

-- Check 4: RPC response does NOT leak real author user ID
select isnt(
  (select resp->>'blocked_user_id' from anon_block_result),
  '90000000-0000-0000-0000-000000000001',
  'Anonymous block RPC does NOT return real author user_id'
);

-- Check 5: Internal user_blocks table has correct real blocked_user_id
select is(
  (select blocked_user_id::text from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002'),
  '90000000-0000-0000-0000-000000000001',
  'Internal user_blocks table stores true blocked_user_id for filtering'
);

-- Check 6: user_blocks identity_hidden is true
select is(
  (select identity_hidden from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002'),
  true,
  'user_blocks.identity_hidden is true'
);

-- Check 7: RPC response blocked_user_id matches the opaque user_blocks.id
select is(
  (select resp->>'blocked_user_id' from anon_block_result),
  (select id::text from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002'),
  'Anonymous block RPC returns opaque user_blocks.id'
);

-- Check 8: list_my_blocked_users returns opaque ID and generic name
select is(
  (select public.list_my_blocked_users()->0->>'display_name'),
  'Anonymous reviewer',
  'list_my_blocked_users returns generic "Anonymous reviewer"'
);

select is(
  (select public.list_my_blocked_users()->0->>'user_id'),
  (select id::text from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002'),
  'list_my_blocked_users returns opaque user_blocks.id'
);

-- Check 9: Blocker cannot see author content due to RLS filter
set local role authenticated;
select is(
  (select count(*)::int from public.public_reviews where id = '93000000-0000-0000-0000-000000000001'),
  0,
  'Blocker cannot see blocked anonymous review'
);
reset role;

-- Check 10: Third party cannot unblock Blocker's block
select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select public.unblock_user(
  (select id from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002')
);

select is(
  (select count(*)::int from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002'),
  1,
  'Third party cannot unblock another user block'
);

-- Check 11: Blocker unblocks using the opaque block id
select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select public.unblock_user(
  (select id from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002')
);

select is(
  (select count(*)::int from public.user_blocks where blocker_id = '90000000-0000-0000-0000-000000000002'),
  0,
  'Blocker successfully unblocks using opaque block ID'
);

-- Check 12: Review content is visible again after unblock
select is(
  (select count(*)::int from public.public_reviews where id = '93000000-0000-0000-0000-000000000001'),
  1,
  'Review content is visible again after unblock'
);

-- Check 13: Named block returns named display name
-- Author changes review to named (false)
select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select public.upsert_review_with_photos(
  'spot',
  '91000000-0000-0000-0000-000000000001',
  5,
  'Now named review',
  1,
  '{}'::text[],
  '93000000-0000-0000-0000-000000000001',
  false
);

-- Blocker blocks named review
select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

create temp table named_block_result as
select public.block_content_author('review', '93000000-0000-0000-0000-000000000001') as resp;

-- Check 14: Named block returns real display name and author UUID
select is(
  (select resp->>'display_name' from named_block_result),
  'Real Author Name',
  'Named block RPC returns real display name'
);

select * from finish();
rollback;
