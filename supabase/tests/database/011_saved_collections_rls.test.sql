begin;

create extension if not exists pgtap with schema extensions;
select plan(22);

-- Setup test users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '70000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'col-user1@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Col User One"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '70000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'col-user2@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Col User Two"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

-- Create test spot & restaurant
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
  'Pulau Pinang', 'George Town', 'Hill Road', '$', 'Sunset',
  'Enjoy view', 5.42, 100.27,
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
  'Pulau Pinang', 'George Town', 'Hill Road', '$', 'Sunset',
  'Enjoy view', 5.42, 100.27, 'spot-images/sample-spot.jpg'
);

-- Test 1: Anonymous cannot read collections or collection items
set local role anon;
select throws_ok(
  $$select count(*) from public.saved_collections$$,
  '42501', null,
  'anonymous users cannot read saved collections'
);

-- Authenticate as User 1
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

-- Test 2: Direct insert blocked by RLS
select throws_ok(
  $$insert into public.saved_collections (user_id, name) values (auth.uid(), 'Direct Insert')$$,
  '42501', null,
  'direct insert into saved_collections is rejected'
);

-- Test 3: Create collection via RPC returns user_id
select is(
  (select (public.create_saved_collection('Penang Weekend', 'First description') ->> 'user_id')::uuid),
  '70000000-0000-0000-0000-000000000001'::uuid,
  'create_saved_collection RPC creates collection and returns user_id'
);

-- Test 4: Duplicate case-insensitive name rejected
select throws_ok(
  $$select public.create_saved_collection('  penang weekend  ')$$,
  '23505', 'A collection with this name already exists',
  'duplicate collection name is rejected'
);

-- Test 5: Create a second collection
select lives_ok(
  $$select public.create_saved_collection('Heritage Walk', 'Historical sights')$$,
  'create second collection succeeds'
);

-- Test 6: Rename collection and clear description
select is(
  (select (public.rename_saved_collection(
    (select id from public.saved_collections where name = 'Penang Weekend'),
    'Penang Food Tour',
    ''
  ) ->> 'description')),
  null,
  'rename_saved_collection clears description when blank string is passed'
);

-- Test 7: Add place to multiple collections
select lives_ok(
  $$select public.set_place_collections(
    'spot',
    '71000000-0000-0000-0000-000000000001',
    (select array_agg(id) from public.saved_collections where user_id = auth.uid())
  )$$,
  'set_place_collections attaches place to both user collections'
);

-- Test 8: Verify saved_places row exists
select is(
  (select count(*) from public.saved_places where user_id = auth.uid()),
  1::bigint,
  'saved_places row exists for attached place'
);

-- Test 9: Verify saved_collection_items has 2 memberships
select is(
  (select count(*) from public.saved_collection_items where collection_id in (
    select id from public.saved_collections where user_id = auth.uid()
  )),
  2::bigint,
  'saved_collection_items has 2 memberships'
);

-- Test 10: fetch_collection_places returns resolved spot metadata
select is(
  (select (public.fetch_collection_places(
    (select id from public.saved_collections where name = 'Penang Food Tour')
  ) -> 0 ->> 'name')),
  'Penang Hill View',
  'fetch_collection_places returns resolved spot name'
);

-- Test 11: list_my_saved_collections returns correct item count and cover metadata
select is(
  (select (c ->> 'item_count')::int from jsonb_array_elements(public.list_my_saved_collections()) c where c ->> 'name' = 'Penang Food Tour'),
  1,
  'list_my_saved_collections reports item_count = 1'
);

select is(
  (select jsonb_array_length(c -> 'cover_items')
   from jsonb_array_elements(public.list_my_saved_collections()) c
   where c ->> 'name' = 'Penang Food Tour'),
  1,
  'list_my_saved_collections returns one ordered logical cover item'
);

-- Switch to User 2
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

-- Test 12: User 2 cannot read User 1 collections
select is(
  (select count(*) from public.saved_collections),
  0::bigint,
  'user 2 cannot read user 1 saved collections'
);

-- Test 13: User 2 cannot read User 1 collection items
select is(
  (select count(*) from public.saved_collection_items),
  0::bigint,
  'user 2 cannot read user 1 collection items'
);

-- Test 14: User 2 cannot rename User 1 collection
select throws_ok(
  $$select public.rename_saved_collection(
    (select id from public.saved_collections limit 1),
    'Hacked Name'
  )$$,
  'P0002', 'Collection not found',
  'user 2 cannot rename user 1 collection'
);

-- Test 15: User 2 cannot delete User 1 collection
select throws_ok(
  $$select public.delete_saved_collection(
    (select id from public.saved_collections limit 1)
  )$$,
  'P0002', 'Collection not found',
  'user 2 cannot delete user 1 collection'
);

-- Test 16: User 2 creates own collection
select lives_ok(
  $$select public.create_saved_collection('User 2 Favorites')$$,
  'user 2 creates own collection'
);

-- Test 17: Cross-user membership trigger invariant prevents cross-user attachment
reset role;
select throws_ok(
  $$insert into public.saved_collection_items (collection_id, saved_place_id)
    values (
      (select id from public.saved_collections where user_id = '70000000-0000-0000-0000-000000000002' limit 1),
      (select id from public.saved_places where user_id = '70000000-0000-0000-0000-000000000001' limit 1)
    )$$,
  '42501', 'Cannot add place owned by another user to this collection',
  'trigger prevents cross-user collection item insertion'
);

-- Switch back to User 1
select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

-- Test 18: Remove place from 1 of 2 collections keeps saved_places row
select lives_ok(
  $$select public.set_place_collections(
    'spot',
    '71000000-0000-0000-0000-000000000001',
    array[(select id from public.saved_collections where name = 'Heritage Walk')]
  )$$,
  'remove from 1 collection succeeds'
);

select is(
  (select count(*) from public.saved_places where user_id = auth.uid()),
  1::bigint,
  'saved_places row remains intact when place is still in another collection'
);

-- Test 19: Remove place from all collections deletes saved_places row
select lives_ok(
  $$select public.set_place_collections(
    'spot',
    '71000000-0000-0000-0000-000000000001',
    array[]::uuid[]
  )$$,
  'remove from all collections succeeds'
);

select is(
  (select count(*) from public.saved_places where user_id = auth.uid()),
  0::bigint,
  'saved_places row is deleted when removed from all collections'
);

select * from finish();
rollback;
