begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(35);

select has_column('public', 'spot_revisions', 'google_place_id',
  'Spot revisions store stable Google identity');
select has_column('public', 'published_spots', 'place_provider',
  'published Spots expose place provider');
select has_column('public', 'restaurant_revisions', 'google_place_id',
  'Eat revisions store stable Google identity');
select has_column('public', 'published_restaurants', 'place_provider',
  'published Eats expose place provider');
select has_index('public', 'published_spots', 'published_spots_one_google_identity',
  'approved Spots prevent duplicate Google identities within the content type');
select has_index('public', 'published_restaurants', 'published_restaurants_one_google_identity',
  'approved Eats prevent duplicate Google identities within the content type');
select has_function('public', 'lookup_place_enrichments', array['text[]'],
  'public batched enrichment lookup exists');
select ok(has_function_privilege(
  'anon', 'public.lookup_place_enrichments(text[])', 'execute'),
  'anonymous discovery can batch approved enrichment summaries');

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   'e2600000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'unified-tourist@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Unified Tourist"}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('00000000-0000-0000-0000-000000000000',
   'e2600000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'unified-creator@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Unified Creator"}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('00000000-0000-0000-0000-000000000000',
   'e2600000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'unified-admin@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Unified Admin"}'::jsonb, clock_timestamp(), clock_timestamp());

update public.user_roles
set role='influencer', granted_by='e2600000-0000-0000-0000-000000000003'
where user_id='e2600000-0000-0000-0000-000000000002' and revoked_at is null;
update public.user_roles
set role='admin', granted_by='e2600000-0000-0000-0000-000000000003'
where user_id='e2600000-0000-0000-0000-000000000003' and revoked_at is null;

insert into storage.objects(bucket_id,name,owner) values
  ('spot-images','e2600000-0000-0000-0000-000000000001/unified_spot.jpg',
   'e2600000-0000-0000-0000-000000000001'),
  ('restaurant-images','e2600000-0000-0000-0000-000000000002/unified_eat.jpg',
   'e2600000-0000-0000-0000-000000000002');

select set_config('request.jwt.claims',
  '{"sub":"e2600000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($sql$select public.accept_current_ugc_rules()$sql$,
  'tourist accepts contribution rules');
select lives_ok($sql$select public.create_spot_draft_v2(
  'Unified Market', 'Culture', 'A local market with useful experiential context.',
  'Pulau Pinang', 'George Town', '12 Lebuh Unified, 10200 George Town, Pulau Pinang',
  '$', 'Morning', 'Browse the wet market',
  'e2600000-0000-0000-0000-000000000001/unified_spot.jpg',
  5.4201, 100.3301, 'google', 'ChIJUnifiedDestination20260829')$sql$,
  'Google-backed Spot draft is created');
select lives_ok($sql$select public.confirm_spot_image_rights(
  (select current_revision_id from public.spots where owner_id=auth.uid()))$sql$,
  'Spot rights are confirmed');
select lives_ok($sql$select public.submit_spot_revision(
  (select current_revision_id from public.spots where owner_id=auth.uid()), null)$sql$,
  'Google identity survives Spot draft submission');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"e2600000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($sql$select public.accept_current_ugc_rules()$sql$,
  'creator accepts contribution rules');
select lives_ok($sql$select public.create_restaurant_draft_v2(
  'Unified Market', '12 Lebuh Unified, 10200 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Hawker', '$', 'Char koay teow',
  'https://www.instagram.com/p/UnifiedPlace123/',
  'e2600000-0000-0000-0000-000000000002/unified_eat.jpg',
  5.4201, 100.3301, true, 'instagram',
  'google', 'ChIJUnifiedDestination20260829')$sql$,
  'Google-backed Eat draft is created');
select lives_ok($sql$select public.save_restaurant_revision_draft_v2(
  (select current_revision_id from public.restaurants where owner_id=auth.uid()),
  'Unified Market', '12 Lebuh Unified, 10200 George Town, Pulau Pinang',
  'Pulau Pinang', 'George Town', 'Hawker', '$', 'Char koay teow',
  'https://www.instagram.com/p/UnifiedPlace123/',
  'e2600000-0000-0000-0000-000000000002/unified_eat.jpg',
  5.4201, 100.3301, true, 'instagram',
  'google', 'ChIJUnifiedDestination20260829')$sql$,
  'Creator can edit the Google-backed Eat draft without losing identity');
select lives_ok($sql$select public.submit_restaurant_revision(
  (select current_revision_id from public.restaurants where owner_id=auth.uid()), null)$sql$,
  'Google identity survives Eat draft submission');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"e2600000-0000-0000-0000-000000000003","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($sql$select public.admin_moderate_spot_revision(
  (select current_revision_id from public.spots
   where owner_id='e2600000-0000-0000-0000-000000000001'),
  'approved', 'Verified exact Google destination', 1)$sql$,
  'Admin approves Google-backed Spot');
select lives_ok($sql$select public.admin_moderate_restaurant_revision(
  (select current_revision_id from public.restaurants
   where owner_id='e2600000-0000-0000-0000-000000000002'),
  'approved', 'Verified exact Google destination', 1)$sql$,
  'Admin approves Google-backed Eat');

reset role;
set local role anon;
select is((select google_place_id from public.published_spots
  where name='Unified Market'), 'ChIJUnifiedDestination20260829',
  'Spot identity survives approval into publication');
select is((select google_place_id from public.published_restaurants
  where name='Unified Market'), 'ChIJUnifiedDestination20260829',
  'Eat identity survives approval into publication');
select is(jsonb_array_length(public.lookup_place_enrichments(
  array['ChIJUnifiedDestination20260829'])), 1,
  'one destination row is returned for two insight types');
select ok((public.lookup_place_enrichments(
  array['ChIJUnifiedDestination20260829'])->0->'spot'->>'id') is not null,
  'batch summary contains approved Spot insight');
select ok((public.lookup_place_enrichments(
  array['ChIJUnifiedDestination20260829'])->0->'eat'->>'id') is not null,
  'batch summary contains approved Eat insight');
select throws_ok($sql$select public.lookup_place_enrichments(array[
  'ChIJ00000001','ChIJ00000002','ChIJ00000003','ChIJ00000004','ChIJ00000005',
  'ChIJ00000006','ChIJ00000007','ChIJ00000008','ChIJ00000009','ChIJ00000010',
  'ChIJ00000011','ChIJ00000012','ChIJ00000013','ChIJ00000014','ChIJ00000015',
  'ChIJ00000016','ChIJ00000017','ChIJ00000018','ChIJ00000019','ChIJ00000020',
  'ChIJ00000021'])$sql$, '22023', null,
  'batch lookup enforces the 20-ID contract');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"e2600000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($sql$select public.create_saved_collection('Unified day', null)$sql$,
  'tourist creates mixed destination collection');
select lives_ok($sql$select public.set_place_collections(
  'spot', (select id::text from public.published_spots where name='Unified Market'),
  array[(select id from public.saved_collections where name='Unified day')])$sql$,
  'saving Google-backed Spot normalizes to provider identity');
select lives_ok($sql$select public.set_place_collections(
  'restaurant', (select id::text from public.published_restaurants where name='Unified Market'),
  array[(select id from public.saved_collections where name='Unified day')])$sql$,
  'saving Google-backed Eat resolves the same destination');
select is((select count(*) from public.saved_places
  where user_id=auth.uid() and external_provider='google'
    and external_place_id='ChIJUnifiedDestination20260829'), 1::bigint,
  'one canonical save exists for Spot and Eat enrichment');
select is((select count(*) from public.saved_collection_items item
  join public.saved_collections collection on collection.id=item.collection_id
  where collection.user_id=auth.uid()), 1::bigint,
  'collection contains the unified destination once');
select is((select item->>'address' from jsonb_array_elements(
  public.fetch_saved_route_candidates()) item),
  '12 Lebuh Unified, 10200 George Town, Pulau Pinang',
  'route candidate exposes a full usable address');
select ok((select (item->>'latitude')::double precision is not null
  and (item->>'longitude')::double precision is not null
  from jsonb_array_elements(public.fetch_saved_route_candidates()) item),
  'route candidate exposes coordinates');
select ok((select item->>'spot_id' is not null and item->>'restaurant_id' is not null
  and item->>'things_to_do'='Browse the wet market'
  and item->>'reviewed_dishes'='Char koay teow'
  from jsonb_array_elements(public.fetch_saved_route_candidates()) item),
  'unified trip stop retains both LiveLocal insight layers');

reset role;
set local role postgres;
set local search_path = public, extensions;
select extensions.lives_ok($sql$select private.assert_valid_guide_stop_details('[
  {"kind":"provider","name":"Unified Market","instruction":"Start at the market",
   "place_provider":"google","google_place_id":"ChIJUnifiedDestination20260829"},
  {"kind":"custom","name":"Hidden lane","instruction":"Walk to the hidden lane"}
]'::jsonb)$sql$, 'Guide stops accept provider-backed destinations');
select extensions.lives_ok($sql$insert into public.spots(id,owner_id) values(
  'e2600000-0000-0000-0000-000000000010','e2600000-0000-0000-0000-000000000001')$sql$,
  'legacy Spot entity remains valid');
select extensions.lives_ok($sql$insert into public.spot_revisions(
  spot_id,revision_number,author_id,name,category,description,state,city,address,
  price_range,best_time,things_to_do,latitude,longitude)
  values('e2600000-0000-0000-0000-000000000010',1,
  'e2600000-0000-0000-0000-000000000001','Legacy Hidden Gem','Nature',
  'Legacy unlinked content remains compatible.','Perak','Ipoh','Old trail address',
  '$','Morning','Walk the trail',4.60,101.09)$sql$,
  'legacy unlinked Spot revision remains valid');

select * from extensions.finish();
rollback;
