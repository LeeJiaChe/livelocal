begin;

create extension if not exists pgtap with schema extensions;
select plan(19);

-- 1. Table privilege tests
select is(
  has_table_privilege('anon', 'public.review_photos', 'SELECT'),
  false,
  'anon role cannot SELECT from public.review_photos'
);

select is(
  has_table_privilege('authenticated', 'public.review_photos', 'SELECT'),
  false,
  'authenticated role cannot directly SELECT from public.review_photos'
);

-- 2. Function execution privileges
select is(
  has_function_privilege('anon', 'public.list_public_review_photos(uuid[])', 'EXECUTE'),
  true,
  'anon role CAN execute list_public_review_photos'
);

select is(
  has_function_privilege('authenticated', 'public.list_public_review_photos(uuid[])', 'EXECUTE'),
  true,
  'authenticated role CAN execute list_public_review_photos'
);

-- 3. Set up test users and content
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '99000000-0000-0000-0000-000000000001', 'authenticated',
    'authenticated', 'photo-author@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Photo Author"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '99000000-0000-0000-0000-000000000002', 'authenticated',
    'authenticated', 'photo-viewer@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Photo Viewer"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

insert into public.spots (id, owner_id)
values ('99100000-0000-0000-0000-000000000001', '99000000-0000-0000-0000-000000000001');

insert into public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category,
  description, state, city, address, price_range, best_time, things_to_do,
  submitted_at, decided_at
)
values (
  '99200000-0000-0000-0000-000000000001',
  '99100000-0000-0000-0000-000000000001',
  1,
  '99000000-0000-0000-0000-000000000001',
  'approved',
  'Photo Privacy Test Spot',
  'Attraction',
  'Spot for testing review photo privacy',
  'Penang',
  'George Town',
  'Campbell St',
  '$',
  'Morning',
  array['Walking'],
  clock_timestamp(),
  clock_timestamp()
);

update public.spots set
  current_revision_id = '99200000-0000-0000-0000-000000000001',
  approved_revision_id = '99200000-0000-0000-0000-000000000001'
where id = '99100000-0000-0000-0000-000000000001';

insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
)
select spot_id, id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
from public.spot_revisions
where id = '99200000-0000-0000-0000-000000000001';

-- Insert mock storage objects in review-images bucket
insert into storage.objects (
  id, bucket_id, name, owner_id, created_at, updated_at
) values (
  gen_random_uuid(),
  'review-images',
  'reviews/99300000-0000-0000-0000-000000000001/photo1.jpg',
  '99000000-0000-0000-0000-000000000001',
  clock_timestamp(),
  clock_timestamp()
), (
  gen_random_uuid(),
  'review-images',
  '99000000-0000-0000-0000-000000000001/99300000-0000-0000-0000-000000000001/legacy_photo.jpg',
  '99000000-0000-0000-0000-000000000001',
  clock_timestamp(),
  clock_timestamp()
);

-- Author creates anonymous review with opaque photo path
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select public.accept_current_ugc_rules();

select public.upsert_review_with_photos(
  'spot',
  '99100000-0000-0000-0000-000000000001',
  5,
  'Review with opaque photo path',
  null,
  array['reviews/99300000-0000-0000-0000-000000000001/photo1.jpg'],
  '99300000-0000-0000-0000-000000000001',
  true
);

-- Check 5: Author attempts to use legacy userId path with is_anonymous = true -> MUST FAIL
select throws_ok(
  $$select public.upsert_review_with_photos(
    'spot',
    '99100000-0000-0000-0000-000000000001',
    5,
    'Attempting leak with legacy path',
    1,
    array['99000000-0000-0000-0000-000000000001/99300000-0000-0000-0000-000000000001/legacy_photo.jpg'],
    '99300000-0000-0000-0000-000000000001',
    true
  )$$,
  '22023',
  'Anonymous review photos must use privacy-safe storage paths',
  'upsert_review_with_photos forbids userId storage paths for anonymous reviews'
);

-- Check 6: Anon user calls list_public_review_photos
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

create temp table anon_photo_res as
select * from public.list_public_review_photos(array['99300000-0000-0000-0000-000000000001'::uuid]);

select is(
  (select count(*)::int from anon_photo_res),
  1,
  'Anon caller gets visible review photos'
);

-- Check 7: Photo storage_path contains NO author user UUID
select is(
  (select storage_path from anon_photo_res),
  'reviews/99300000-0000-0000-0000-000000000001/photo1.jpg',
  'list_public_review_photos returns opaque storage path'
);

select isnt(
  (select storage_path from anon_photo_res),
  '99000000-0000-0000-0000-000000000001',
  'Photo path does NOT contain real author user ID'
);

-- Check 8: Authenticated other user calls list_public_review_photos
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::int from public.list_public_review_photos(array['99300000-0000-0000-0000-000000000001'::uuid])),
  1,
  'Authenticated viewer can retrieve public review photos'
);

-- Check 9: Viewer blocks review author -> photo is no longer returned
select public.block_content_author('review', '99300000-0000-0000-0000-000000000001');

select is(
  (select count(*)::int from public.list_public_review_photos(array['99300000-0000-0000-0000-000000000001'::uuid])),
  0,
  'Blocked review author photos are hidden by list_public_review_photos'
);

-- Check 10: Unblock restores photo visibility
select public.unblock_user(
  (select (public.list_my_blocked_users()->0->>'user_id')::uuid)
);

select is(
  (select count(*)::int from public.list_public_review_photos(array['99300000-0000-0000-0000-000000000001'::uuid])),
  1,
  'Unblocked review author photos are visible again'
);

-- Check 11: Direct SELECT from public.review_photos fails for authenticated viewer
set local role authenticated;
select throws_ok(
  'select * from public.review_photos',
  '42501',
  null,
  'Direct SELECT on review_photos throws permission denied'
);

reset role;

-- Check 12: Storage select policy for review-images
set local role anon;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/99300000-0000-0000-0000-000000000001/photo1.jpg'),
  1,
  'Anon can access published review photo in storage'
);

-- Check 13: Storage select policy denies access to unreferenced/private objects
select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = '99000000-0000-0000-0000-000000000001/99300000-0000-0000-0000-000000000001/legacy_photo.jpg'),
  0,
  'Anon cannot access unreferenced photo in storage'
);

-- Check 14: Authenticated other user can access published review photo in storage
reset role;
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/99300000-0000-0000-0000-000000000001/photo1.jpg'),
  1,
  'Authenticated viewer can access published review photo in storage'
);

-- Check 15: Owner can see their own unreferenced upload
reset role;
select set_config('request.jwt.claim.sub', '99000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = '99000000-0000-0000-0000-000000000001/99300000-0000-0000-0000-000000000001/legacy_photo.jpg'),
  1,
  'Owner can see their own eligible unreferenced upload'
);

-- Check 17: Owner delete on unreferenced upload is permitted by RLS policy and reaches storage trigger
select throws_ok(
  'delete from storage.objects where bucket_id = ''review-images'' and name = ''99000000-0000-0000-0000-000000000001/99300000-0000-0000-0000-000000000001/legacy_photo.jpg''',
  '42501',
  'Direct deletion from storage tables is not allowed. Use the Storage API instead.',
  'Owner delete on unreferenced photo is permitted by policy and reaches storage trigger'
);

-- Check 18-19: Owner cannot delete a referenced review photo (policy blocks row / 0 rows matched)
select lives_ok(
  'delete from storage.objects where bucket_id = ''review-images'' and name = ''reviews/99300000-0000-0000-0000-000000000001/photo1.jpg''',
  'Owner delete on referenced photo is blocked by policy without reaching trigger'
);

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/99300000-0000-0000-0000-000000000001/photo1.jpg'),
  1,
  'Referenced review photo remains intact in storage.objects'
);

select * from finish();
rollback;
