begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

-- 1. anon cannot SELECT public.review_photos directly
select is(
  has_table_privilege('anon', 'public.review_photos', 'SELECT'),
  false,
  '1. anon role cannot SELECT directly from public.review_photos'
);

-- 2. authenticated cannot SELECT public.review_photos directly
select is(
  has_table_privilege('authenticated', 'public.review_photos', 'SELECT'),
  false,
  '2. authenticated role cannot SELECT directly from public.review_photos'
);

-- Setup test users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '88000000-0000-0000-0000-000000000001', 'authenticated',
    'authenticated', 'hardening-author@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Hardening Author"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '88000000-0000-0000-0000-000000000002', 'authenticated',
    'authenticated', 'hardening-viewer@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Hardening Viewer"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

insert into public.spots (id, owner_id)
values ('88100000-0000-0000-0000-000000000001', '88000000-0000-0000-0000-000000000001');

insert into public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category,
  description, state, city, address, price_range, best_time, things_to_do,
  submitted_at, decided_at
) values (
  '88200000-0000-0000-0000-000000000001',
  '88100000-0000-0000-0000-000000000001', 1,
  '88000000-0000-0000-0000-000000000001', 'approved',
  'Hardening Spot', 'Attraction',
  'Spot for testing review photo storage policy hardening',
  'Penang', 'George Town', 'Armenian St', '$', 'Morning',
  array['Walking'], clock_timestamp(), clock_timestamp()
);

-- Mock storage objects
insert into storage.objects (id, bucket_id, name, owner_id, created_at, updated_at)
values
  (
    gen_random_uuid(), 'review-images',
    'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg',
    '88000000-0000-0000-0000-000000000001',
    clock_timestamp(), clock_timestamp()
  ),
  (
    gen_random_uuid(), 'review-images',
    '88000000-0000-0000-0000-000000000001/88300000-0000-0000-0000-000000000001/unreferenced.jpg',
    '88000000-0000-0000-0000-000000000001',
    clock_timestamp(), clock_timestamp()
  );

-- Author creates anonymous review with opaque photo path
select set_config('request.jwt.claim.sub', '88000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select public.upsert_review_with_photos(
  'spot',
  '88100000-0000-0000-0000-000000000001',
  5,
  'Hardened review test content',
  null,
  array['reviews/88300000-0000-0000-0000-000000000001/photo1.jpg'],
  '88300000-0000-0000-0000-000000000001',
  true
);

-- 3. anon can access the Storage object for a published visible review photo
set local role anon;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg'),
  1,
  '3. anon can access the Storage object for a published visible review photo'
);

-- 4. authenticated other user can access a visible published review photo
reset role;
select set_config('request.jwt.claim.sub', '88000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg'),
  1,
  '4. authenticated other user can access a visible published review photo'
);

-- 5. blocked review photo is not accessible
select public.block_content_author('review', '88300000-0000-0000-0000-000000000001');

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg'),
  0,
  '5. blocked/hidden review photo is not accessible via Storage RLS'
);

-- Unblock
select public.unblock_user((select (public.list_my_blocked_users()->0->>'user_id')::uuid));

-- 6. owner can see their own eligible unreferenced upload
reset role;
select set_config('request.jwt.claim.sub', '88000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = '88000000-0000-0000-0000-000000000001/88300000-0000-0000-0000-000000000001/unreferenced.jpg'),
  1,
  '6. owner can see their own eligible unreferenced upload'
);

-- 7. owner can delete an unreferenced review image
select lives_ok(
  $$delete from storage.objects where bucket_id = 'review-images' and name = '88000000-0000-0000-0000-000000000001/88300000-0000-0000-0000-000000000001/unreferenced.jpg$$,
  '7. owner can delete an unreferenced review image'
);

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = '88000000-0000-0000-0000-000000000001/88300000-0000-0000-0000-000000000001/unreferenced.jpg'),
  0,
  '7b. unreferenced review image is confirmed deleted'
);

-- 8. owner cannot delete a referenced review image
select lives_ok(
  $$delete from storage.objects where bucket_id = 'review-images' and name = 'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg'$$,
  '8. attempting to delete referenced review photo does not throw uncaught error'
);

select is(
  (select count(*)::int from storage.objects where bucket_id = 'review-images' and name = 'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg'),
  1,
  '8b. referenced review photo remains protected in storage.objects'
);

-- 10. anonymous review photos remain opaque and do not leak owner/user UUID
select is(
  (select storage_path from public.list_public_review_photos(array['88300000-0000-0000-0000-000000000001'::uuid])),
  'reviews/88300000-0000-0000-0000-000000000001/photo1.jpg',
  '10. list_public_review_photos returns opaque storage path without user ID'
);

select isnt(
  (select storage_path from public.list_public_review_photos(array['88300000-0000-0000-0000-000000000001'::uuid])),
  '88000000-0000-0000-0000-000000000001',
  '10b. photo path does not equal or contain author user ID'
);

select * from finish();
rollback;
