begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

-- Setup test users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '70000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'route-user1@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Route User One"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '70000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'route-user2@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Route User Two"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

-- Create published spot
insert into public.spots (id, owner_id)
values ('71000000-0000-0000-0000-000000000001', '70000000-0000-0000-0000-000000000001');

insert into public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category,
  description, state, city, address, price_range, best_time, things_to_do,
  latitude, longitude, submitted_at, decided_at
)
values (
  '72000000-0000-0000-0000-000000000001',
  '71000000-0000-0000-0000-000000000001', 1,
  '70000000-0000-0000-0000-000000000001', 'approved',
  'Penang Hill View', 'Nature',
  'Scenic spot on Penang Hill.',
  'Pulau Pinang', 'George Town', 'Hill Road', '$', 'Morning',
  'Enjoy panoramic view', 5.4243, 100.2691,
  clock_timestamp(), clock_timestamp()
);

update public.spots set
  current_revision_id = '72000000-0000-0000-0000-000000000001',
  approved_revision_id = '72000000-0000-0000-0000-000000000001'
where id = '71000000-0000-0000-0000-000000000001';

insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do, latitude, longitude, image_path
)
values (
  '71000000-0000-0000-0000-000000000001',
  '72000000-0000-0000-0000-000000000001',
  'Penang Hill View', 'Nature',
  'Scenic spot on Penang Hill.',
  'Pulau Pinang', 'George Town', 'Hill Road', '$', 'Morning',
  'Enjoy panoramic view', 5.4243, 100.2691, 'spots/penang_hill.jpg'
);

-- Create published restaurant
insert into public.restaurants (id, owner_id)
values ('73000000-0000-0000-0000-000000000001', '70000000-0000-0000-0000-000000000001');

insert into public.restaurant_revisions (
  id, restaurant_id, revision_number, author_id, status, name, cuisine_type,
  price_range, reviewed_dishes, address, state, city, latitude, longitude,
  social_media_url, submitted_at, decided_at
)
values (
  '74000000-0000-0000-0000-000000000001',
  '73000000-0000-0000-0000-000000000001', 1,
  '70000000-0000-0000-0000-000000000001', 'approved',
  'Line Clear Nasi Kandar', 'Malaysian',
  '$$', 'Nasi Kandar with Fried Chicken', 'Penang Road', 'Pulau Pinang', 'George Town',
  5.4188, 100.3328, 'https://instagram.com/lineclear',
  clock_timestamp(), clock_timestamp()
);

update public.restaurants set
  current_revision_id = '74000000-0000-0000-0000-000000000001',
  approved_revision_id = '74000000-0000-0000-0000-000000000001'
where id = '73000000-0000-0000-0000-000000000001';

insert into public.published_restaurants (
  id, revision_id, name, address, state, city, cuisine_type, price_range,
  reviewed_dishes, social_media_url, cover_image_path, ownership_status,
  latitude, longitude
)
values (
  '73000000-0000-0000-0000-000000000001',
  '74000000-0000-0000-0000-000000000001',
  'Line Clear Nasi Kandar', 'Penang Road', 'Pulau Pinang', 'George Town',
  'Malaysian', '$$', 'Nasi Kandar with Fried Chicken',
  'https://instagram.com/lineclear', 'restaurants/line_clear.jpg', 'unclaimed',
  5.4188, 100.3328
);

-- Test 1: Anonymous cannot call fetch_saved_route_candidates
set local role anon;
select throws_ok(
  $$select public.fetch_saved_route_candidates()$$,
  '42501', null,
  'anon cannot call fetch_saved_route_candidates'
);

-- Switch to User 1
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

-- Test 2: User 1 has 0 candidates initially
select is(
  public.fetch_saved_route_candidates(),
  '[]'::jsonb,
  'empty saved route candidates when nothing saved'
);

-- Create collection and save places for User 1
select public.create_saved_collection('Penang Weekend', 'Weekend spots');

select public.set_place_collections(
  'spot',
  '71000000-0000-0000-0000-000000000001',
  array[(select id from public.saved_collections where name = 'Penang Weekend')]
);

select public.set_place_collections(
  'restaurant',
  '73000000-0000-0000-0000-000000000001',
  array[(select id from public.saved_collections where name = 'Penang Weekend')]
);

-- Test 3: User 1 gets 2 candidates for all saved places
select is(
  (select jsonb_array_length(public.fetch_saved_route_candidates())),
  2,
  'returns 2 route candidates for all saved places'
);

-- Test 4: User 1 gets 2 candidates for Penang Weekend collection
select is(
  (select jsonb_array_length(public.fetch_saved_route_candidates(
    (select id from public.saved_collections where name = 'Penang Weekend')
  ))),
  2,
  'returns 2 route candidates for specific collection'
);

-- Test 5: Verify exact coordinates and spot-specific metadata on candidates
select is(
  (select (elem ->> 'latitude')::numeric from jsonb_array_elements(public.fetch_saved_route_candidates()) elem where elem ->> 'target_type' = 'spot'),
  5.4243::numeric,
  'spot candidate has exact latitude'
);

select is(
  (select (elem ->> 'longitude')::numeric from jsonb_array_elements(public.fetch_saved_route_candidates()) elem where elem ->> 'target_type' = 'spot'),
  100.2691::numeric,
  'spot candidate has exact longitude'
);

-- Test 6: Verify spot-specific best_time and things_to_do are returned
select is(
  (select elem ->> 'best_time' from jsonb_array_elements(public.fetch_saved_route_candidates()) elem where elem ->> 'target_type' = 'spot'),
  'Morning',
  'spot candidate has real best_time'
);

select is(
  (select elem ->> 'things_to_do' from jsonb_array_elements(public.fetch_saved_route_candidates()) elem where elem ->> 'target_type' = 'spot'),
  'Enjoy panoramic view',
  'spot candidate has real things_to_do'
);

-- Test 7: Verify restaurant-specific reviewed_dishes is returned
select is(
  (select elem ->> 'reviewed_dishes' from jsonb_array_elements(public.fetch_saved_route_candidates()) elem where elem ->> 'target_type' = 'restaurant'),
  'Nasi Kandar with Fried Chicken',
  'restaurant candidate has real reviewed_dishes'
);

-- Switch to User 2
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

-- Test 8: User 2 sees 0 candidates (no cross-user leakage)
select is(
  public.fetch_saved_route_candidates(),
  '[]'::jsonb,
  'User 2 sees 0 route candidates from User 1 saved places'
);

-- Test 9: User 2 cannot request User 1 collection ID
select throws_ok(
  format(
    'select public.fetch_saved_route_candidates(%L::uuid)',
    (select id from public.saved_collections where name = 'Penang Weekend')
  ),
  'P0002', 'Collection not found',
  'cannot access another user collection route candidates'
);

-- Test 10: User 2 creates collection, saves spot, requests candidates
select public.create_saved_collection('User 2 Trips');
select public.set_place_collections(
  'spot',
  '71000000-0000-0000-0000-000000000001',
  array[(select id from public.saved_collections where name = 'User 2 Trips')]
);

select is(
  (select jsonb_array_length(public.fetch_saved_route_candidates(
    (select id from public.saved_collections where name = 'User 2 Trips')
  ))),
  1,
  'User 2 gets own candidate for own collection'
);

select * from finish();
rollback;
