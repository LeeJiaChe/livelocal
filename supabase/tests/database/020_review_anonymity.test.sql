begin;

create extension if not exists pgtap with schema extensions;
select plan(25);

-- 1. Schema checks
select col_type_is(
  'public', 'reviews', 'is_anonymous', 'boolean',
  'public.reviews has is_anonymous boolean column'
);

select col_default_is(
  'public', 'reviews', 'is_anonymous', 'false',
  'public.reviews.is_anonymous defaults to false'
);

select col_type_is(
  'public', 'public_reviews', 'is_anonymous', 'boolean',
  'public.public_reviews has is_anonymous boolean column'
);

select col_default_is(
  'public', 'public_reviews', 'is_anonymous', 'false',
  'public.public_reviews.is_anonymous defaults to false'
);

select hasnt_column(
  'public', 'public_reviews', 'user_id',
  'public.public_reviews has no user_id column (Guest/anon cannot obtain user_id)'
);

-- 2. Function privilege checks
select ok(
  has_function_privilege(
    'authenticated',
    'public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid,boolean)',
    'execute'
  ),
  'authenticated users can call the 8-parameter review RPC'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid)',
    'execute'
  ),
  'authenticated users can call the 7-parameter backward-compatible review RPC'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid,boolean)',
    'execute'
  ),
  'anon users cannot call the 8-parameter review RPC'
);

-- 3. Functional behavior tests with test accounts and spot
do $$
declare
  v_tourist_id uuid := '11111111-1111-4111-a111-111111111111';
  v_spot_id uuid := '22222222-2222-4222-a222-222222222222';
  v_res jsonb;
begin
  -- Setup test tourist profile
  insert into auth.users (id, email, email_confirmed_at)
  values (v_tourist_id, 'tourist_test@example.com', clock_timestamp())
  on conflict (id) do update set email_confirmed_at = clock_timestamp();

  insert into public.account_access (user_id, status)
  values (v_tourist_id, 'active')
  on conflict (user_id) do update set status = 'active';

  insert into public.profiles (id, display_name)
  values (v_tourist_id, 'Real Tourist Name')
  on conflict (id) do update set display_name = 'Real Tourist Name';

  -- Accept UGC rules
  insert into public.user_ugc_rule_acceptances (user_id, rule_version)
  values (v_tourist_id, '2026-08')
  on conflict (user_id, rule_version) do nothing;

  -- Setup published spot
  insert into public.spots (id, owner_id)
  values (v_spot_id, v_tourist_id)
  on conflict (id) do nothing;

  insert into public.spot_revisions (
    id, spot_id, revision_number, author_id, status, name, category,
    description, state, city, address, price_range, best_time, things_to_do,
    submitted_at, decided_at
  ) values (
    '22222222-2222-4222-a222-222222222223', v_spot_id, 1, v_tourist_id, 'approved',
    'Test Anonymity Spot', 'Attraction', 'This is a valid test spot description for anonymity tests', 'Penang', 'George Town', '123 Test St', '$', 'Morning',
    array['Walk'], clock_timestamp(), clock_timestamp()
  ) on conflict (id) do nothing;

  update public.spots set
    current_revision_id = '22222222-2222-4222-a222-222222222223',
    approved_revision_id = '22222222-2222-4222-a222-222222222223'
  where id = v_spot_id;

  insert into public.published_spots (
    id, revision_id, name, category, description, state, city, address,
    price_range, best_time, things_to_do
  )
  select spot_id, id, name, category, description, state, city, address,
    price_range, best_time, things_to_do
  from public.spot_revisions
  where id = '22222222-2222-4222-a222-222222222223'
  on conflict (id) do nothing;
end;
$$;

-- Test Named review submission
set local role authenticated;
set local request.jwt.claims to '{"sub": "11111111-1111-4111-a111-111111111111", "role": "authenticated"}';

select lives_ok(
  $$
    select public.upsert_review_with_photos(
      'spot',
      '22222222-2222-4222-a222-222222222222',
      5,
      'Great spot with real name!',
      null,
      '{}'::text[],
      null,
      false
    );
  $$,
  'tourist creates named review'
);

select is(
  (select author_display_name from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  'Real Tourist Name',
  'named review exposes actual display name in public_reviews'
);

select is(
  (select is_anonymous from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  false,
  'named review has public_reviews.is_anonymous = false'
);

select is(
  (select is_anonymous from public.reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  false,
  'named review has reviews.is_anonymous = false'
);

-- Test switching Named -> Anonymous (Editing existing review)
select lives_ok(
  $$
    select public.upsert_review_with_photos(
      'spot',
      '22222222-2222-4222-a222-222222222222',
      4,
      'Updated to anonymous review!',
      1,
      '{}'::text[],
      null,
      true
    );
  $$,
  'tourist edits review and turns anonymity ON'
);

select is(
  (select user_id from public.reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  '11111111-1111-4111-a111-111111111111'::uuid,
  'anonymous review internally retains author user_id'
);

select is(
  (select author_display_name from public.reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  'Real Tourist Name',
  'anonymous review internally retains author_display_name'
);

select is(
  (select is_anonymous from public.reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  true,
  'anonymous review has reviews.is_anonymous = true'
);

select is(
  (select author_display_name from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  'Anonymous',
  'anonymous review projects author_display_name as Anonymous in public_reviews'
);

select is(
  (select is_anonymous from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  true,
  'anonymous review has public_reviews.is_anonymous = true'
);

-- Test switching Anonymous -> Named (Editing again)
select lives_ok(
  $$
    select public.upsert_review_with_photos(
      'spot',
      '22222222-2222-4222-a222-222222222222',
      5,
      'Switched back to named review!',
      2,
      '{}'::text[],
      null,
      false
    );
  $$,
  'tourist edits review and turns anonymity OFF'
);

select is(
  (select author_display_name from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  'Real Tourist Name',
  'editing from Anonymous -> Named republishes real display name in public_reviews'
);

select is(
  (select is_anonymous from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  false,
  'editing from Anonymous -> Named sets public_reviews.is_anonymous = false'
);

-- Test 7-arg backward-compatible RPC
select lives_ok(
  $$
    select public.upsert_review_with_photos(
      'spot',
      '22222222-2222-4222-a222-222222222222',
      5,
      'Called via 7-arg legacy RPC signature',
      3,
      '{}'::text[],
      null
    );
  $$,
  '7-arg legacy RPC succeeds'
);

select is(
  (select is_anonymous from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  false,
  '7-arg legacy RPC defaults to is_anonymous = false'
);

-- Test delete_my_review
select lives_ok(
  $$
    select public.delete_my_review(
      (select id from public.reviews where target_id = '22222222-2222-4222-a222-222222222222'),
      4
    );
  $$,
  'delete_my_review successfully deletes the review'
);

select is(
  (select count(*) from public.public_reviews where target_id = '22222222-2222-4222-a222-222222222222'),
  0::bigint,
  'deleted review is removed from public_reviews'
);

select * from finish();
rollback;
