begin;

set session_replication_role = replica;

create extension if not exists pgtap with schema extensions;
select plan(10);

-- ============================================================
-- Setup: create test users
-- ============================================================

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'f0000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'storage-policy-tester@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Storage Tester"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'f0000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'storage-owner@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Storage Owner"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

-- Give the second user admin role for owner/admin tests
update public.user_roles
set revoked_at = clock_timestamp(),
    revoked_by = 'f0000000-0000-0000-0000-000000000002'
where user_id = 'f0000000-0000-0000-0000-000000000002'
  and revoked_at is null;
insert into public.user_roles (user_id, role, granted_by)
values (
  'f0000000-0000-0000-0000-000000000002', 'admin',
  'f0000000-0000-0000-0000-000000000002'
);

-- Ensure the admin user has active account_access so private.is_admin() works
insert into public.account_access (user_id, status)
values ('f0000000-0000-0000-0000-000000000002', 'active');

-- ============================================================
-- Setup: insert base spots and revisions to satisfy foreign keys
-- ============================================================

insert into public.spots (id) values 
  ('f0000000-1000-0000-0000-000000000001'),
  ('f0000000-1000-0000-0000-000000000002');

insert into public.spot_revisions (
  id, spot_id, revision_number, name, category, description, state, city, address, price_range, best_time, things_to_do
)
values (
  'f0000000-1000-0000-0000-000000000011', 'f0000000-1000-0000-0000-000000000001', 1,
  'Published Spot One', 'Nature', 'This is a very beautiful spot indeed', 'Selangor', 'Shah Alam', '123 Test Road', '$$', 'Morning', 'Hiking'
),
(
  'f0000000-1000-0000-0000-000000000012', 'f0000000-1000-0000-0000-000000000002', 1,
  'No Image Spot', 'Food', 'This is a spot without an image attached', 'KL', 'Bukit Bintang', '456 Test Lane', '$', 'Evening', 'Eating'
);

-- ============================================================
-- Setup: insert published spots with DIFFERENT name vs image_path
-- This is the key: if the policy incorrectly compares ps.image_path = ps.name,
-- the SELECT will fail because 'Published Spot One' != 'f0.../published-spot.jpg'
-- ============================================================

insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path
)
values (
  'f0000000-1000-0000-0000-000000000001',
  'f0000000-1000-0000-0000-000000000011',
  'Published Spot One',
  'Nature', 'This is a very beautiful spot indeed', 'Selangor', 'Shah Alam', '123 Test Road',
  '$$', 'Morning', 'Hiking',
  'f0000000-0000-0000-0000-000000000001/published-spot.jpg'
);

-- Published spot with NULL image_path (should not match any storage object)
insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, image_path
)
values (
  'f0000000-1000-0000-0000-000000000002',
  'f0000000-1000-0000-0000-000000000012',
  'No Image Spot',
  'Food', 'This is a spot without an image attached', 'KL', 'Bukit Bintang', '456 Test Lane',
  '$', 'Evening', 'Eating',
  null
);

-- ============================================================
-- Setup: insert base restaurants and revisions
-- ============================================================

insert into public.restaurants (id) values 
  ('f0000000-2000-0000-0000-000000000001');

insert into public.restaurant_revisions (
  id, restaurant_id, revision_number, name, address, state, city, cuisine_type, price_range, reviewed_dishes, social_media_url
)
values (
  'f0000000-2000-0000-0000-000000000011', 'f0000000-2000-0000-0000-000000000001', 1,
  'Published Restaurant One', '789 Food Street', 'Penang', 'George Town', 'Malaysian', '$$$', 'Nasi Lemak, Char Kuey Teow', 'https://instagram.com/resto1'
);

-- ============================================================
-- Setup: insert published restaurant with DIFFERENT name vs cover_image_path
-- ============================================================

insert into public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, ownership_status
)
values (
  'f0000000-2000-0000-0000-000000000001',
  'f0000000-2000-0000-0000-000000000011',
  'Published Restaurant One',
  '789 Food Street', 'Penang', 'George Town', 'Malaysian', '$$$',
  'Nasi Lemak, Char Kuey Teow', 'https://instagram.com/resto1',
  'f0000000-0000-0000-0000-000000000001/published-resto.jpg',
  'claimed'
);

-- ============================================================
-- Setup: insert storage objects
-- ============================================================

-- Spot image that matches published_spots.image_path
insert into storage.objects (bucket_id, name, owner)
values (
  'spot-images',
  'f0000000-0000-0000-0000-000000000001/published-spot.jpg',
  'f0000000-0000-0000-0000-000000000001'
);

-- Spot image that does NOT match any published_spots.image_path
insert into storage.objects (bucket_id, name, owner)
values (
  'spot-images',
  'f0000000-0000-0000-0000-000000000001/unpublished-draft.jpg',
  'f0000000-0000-0000-0000-000000000001'
);

-- Restaurant image that matches published_restaurants.cover_image_path
insert into storage.objects (bucket_id, name, owner)
values (
  'restaurant-images',
  'f0000000-0000-0000-0000-000000000001/published-resto.jpg',
  'f0000000-0000-0000-0000-000000000001'
);

-- Restaurant image that does NOT match any published restaurant
insert into storage.objects (bucket_id, name, owner)
values (
  'restaurant-images',
  'f0000000-0000-0000-0000-000000000001/unpublished-resto.jpg',
  'f0000000-0000-0000-0000-000000000001'
);

-- ============================================================
-- Test 1: Policy definition no longer resolves to ps.name
-- ============================================================

select * from ok(
  (select pg_get_expr(polqual, polrelid, true) from pg_policy
   where polname = 'spot_image_select_authorized')
  !~ 'ps\.image_path = ps\.name',
  'spot policy does NOT compare image_path to subquery name column'
);

select * from ok(
  (select pg_get_expr(polqual, polrelid, true) from pg_policy
   where polname = 'restaurant_image_select_published')
  !~ 'pr\.cover_image_path = pr\.name',
  'restaurant policy does NOT compare cover_image_path to subquery name column'
);

-- ============================================================
-- Test 2: Policy references outer storage.objects.name
-- ============================================================

select * from ok(
  (select pg_get_expr(polqual, polrelid, true) from pg_policy
   where polname = 'spot_image_select_authorized')
  ~ 'objects\.name',
  'spot policy references objects.name (outer storage.objects row)'
);

select * from ok(
  (select pg_get_expr(polqual, polrelid, true) from pg_policy
   where polname = 'restaurant_image_select_published')
  ~ 'objects\.name',
  'restaurant policy references objects.name (outer storage.objects row)'
);

-- ============================================================
-- Test 3-4: Published spot image can be SELECTed by authenticated user
-- ============================================================

select set_config(
  'request.jwt.claims',
  '{"sub":"f0000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select * from is(
  (select count(*)::int from storage.objects
   where bucket_id = 'spot-images'
     and name = 'f0000000-0000-0000-0000-000000000001/published-spot.jpg'),
  1,
  'authenticated user can SELECT published spot image'
);

-- Test 4: Unpublished/non-matching spot image cannot be SELECTed
select * from is(
  (select count(*)::int from storage.objects
   where bucket_id = 'spot-images'
     and name = 'f0000000-0000-0000-0000-000000000001/unpublished-draft.jpg'),
  0,
  'authenticated user cannot SELECT unpublished spot image via published policy'
);

-- ============================================================
-- Test 5-6: Published restaurant image can be SELECTed;
--           unpublished cannot
-- ============================================================

select * from is(
  (select count(*)::int from storage.objects
   where bucket_id = 'restaurant-images'
     and name = 'f0000000-0000-0000-0000-000000000001/published-resto.jpg'),
  1,
  'authenticated user can SELECT published restaurant image'
);

select * from is(
  (select count(*)::int from storage.objects
   where bucket_id = 'restaurant-images'
     and name = 'f0000000-0000-0000-0000-000000000001/unpublished-resto.jpg'),
  0,
  'authenticated user cannot SELECT unpublished restaurant image via published policy'
);

-- ============================================================
-- Test 7-8: Owner/admin storage access remains intact
-- ============================================================

-- Switch to admin user
select set_config(
  'request.jwt.claims',
  '{"sub":"f0000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select * from is(
  (select count(*)::int from storage.objects
   where bucket_id = 'spot-images'
     and name = 'f0000000-0000-0000-0000-000000000001/unpublished-draft.jpg'),
  1,
  'admin can SELECT unpublished spot image via owner/admin policy'
);

select * from is(
  (select count(*)::int from storage.objects
   where bucket_id = 'restaurant-images'
     and name = 'f0000000-0000-0000-0000-000000000001/unpublished-resto.jpg'),
  1,
  'admin can SELECT unpublished restaurant image via owner/admin policy'
);

select * from finish();
rollback;
