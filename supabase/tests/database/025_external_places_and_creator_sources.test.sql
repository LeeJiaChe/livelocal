begin;

create extension if not exists pgtap with schema extensions;
select plan(18);

select has_column('public', 'saved_places', 'external_provider',
  'saved places persist external provider identity');
select has_column('public', 'saved_places', 'external_place_id',
  'saved places persist external place ID');
select has_column('public', 'itinerary_items', 'external_provider',
  'trip stops persist external provider identity');
select has_column('public', 'itinerary_items', 'external_place_id',
  'trip stops persist external place ID');

select ok(
  not has_function_privilege(
    'anon',
    'public.set_place_collections(text,text,uuid[],text)',
    'execute'
  ),
  'guest cannot mutate external saved places'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.set_place_collections(text,text,uuid[],text)',
    'execute'
  ),
  'authenticated user can use external saved-place RPC'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.set_place_collections(text,uuid,uuid[])',
    'execute'
  ),
  'existing internal saved-place RPC remains compatible'
);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values (
  '00000000-0000-0000-0000-000000000000',
  '91000000-0000-0000-0000-000000000001',
  'authenticated', 'authenticated', 'external-place-user@example.test',
  crypt('test-password', gen_salt('bf')), clock_timestamp(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"External Place User"}'::jsonb,
  clock_timestamp(), clock_timestamp()
);

update public.user_roles
set role = 'influencer'
where user_id = '91000000-0000-0000-0000-000000000001'
  and revoked_at is null;

select set_config(
  'request.jwt.claims',
  '{"sub":"91000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.create_saved_collection('Malaysia places', null)$$,
  'user can create collection for provider places'
);

select lives_ok(
  $$select public.set_place_collections(
    'external',
    'ChIJExternalPlace123',
    array[(select id from public.saved_collections where name = 'Malaysia places')],
    'google'
  )$$,
  'Google Place ID can be saved without a copied display payload'
);

select is(
  (select count(*) from public.saved_places
    where external_provider = 'google'
      and external_place_id = 'ChIJExternalPlace123'),
  1::bigint,
  'one deterministic provider identity is stored'
);

select is(
  public.list_place_collection_ids(
    'external', 'ChIJExternalPlace123', 'google'
  ),
  jsonb_build_array(
    (select id from public.saved_collections where name = 'Malaysia places')
  ),
  'external collection membership resolves through owned RPC'
);

select is(
  (select elem->>'target_type'
   from jsonb_array_elements(public.fetch_saved_route_candidates()) elem),
  'external',
  'route candidates include external identity for on-demand resolution'
);

select lives_ok(
  $$select public.create_itinerary_from_saved(
    'Provider place trip', 'Current location', 5.4, 100.3,
    '[{"type":"external","id":"ChIJExternalPlace123","provider":"google"}]'::jsonb
  )$$,
  'saved external identity can complete Trip creation'
);

select is(
  (select external_provider from public.itinerary_items limit 1),
  'google',
  'Trip stores the provider identity'
);

select lives_ok(
  $sql$select public.create_restaurant_draft(
    'AI Maps Draft', '12 Jalan Test', 'Perak', 'Ipoh', 'Malaysian', '$$',
    'Creator checked dish', 'https://maps.app.goo.gl/AbCdEf123456',
    null, null, null, true, 'google_maps'
  )$sql$,
  'Creator can persist a Google Maps AI-assisted draft through the real RPC'
);

reset role;

insert into public.restaurants (
  id, owner_id
) values (
  '92000000-0000-0000-0000-000000000001',
  '91000000-0000-0000-0000-000000000001'
);

select lives_ok(
  $sql$insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    '92000000-0000-0000-0000-000000000001', 1,
    '91000000-0000-0000-0000-000000000001',
    'Maps Restaurant', '12 Jalan Test', 'Perak', 'Ipoh', 'Malaysian', '$$',
    'Creator to complete', 'https://maps.app.goo.gl/AbCdEf123456',
    true, 'google_maps'
  )$sql$,
  'Google Maps may be retained as AI draft provenance'
);

select lives_ok(
  $sql$insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    '92000000-0000-0000-0000-000000000001', 2,
    '91000000-0000-0000-0000-000000000001',
    'Website Restaurant', '12 Jalan Test', 'Perak', 'Ipoh', 'Malaysian', '$$',
    'Creator to complete', 'https://myrestaurant.com.my/menu',
    true, 'website'
  )$sql$,
  'public website may be retained as AI draft provenance'
);

select throws_ok(
  $sql$insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    '92000000-0000-0000-0000-000000000001', 3,
    '91000000-0000-0000-0000-000000000001',
    'Bad Source', '12 Jalan Test', 'Perak', 'Ipoh', 'Malaysian', '$$',
    'Creator to complete', 'http://localhost/private',
    true, 'website'
  )$sql$,
  '23514', null,
  'non-HTTPS/private-style source fails the table contract'
);

select * from finish();
rollback;
