begin;

create extension if not exists pgtap with schema extensions;
select plan(22);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   'a1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'guide-tourist@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Guide Tourist"}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('00000000-0000-0000-0000-000000000000',
   'a1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'guide-admin@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Guide Admin"}'::jsonb, clock_timestamp(), clock_timestamp());

update public.user_roles set revoked_at = clock_timestamp(),
  revoked_by = 'a1000000-0000-0000-0000-000000000002'
where user_id = 'a1000000-0000-0000-0000-000000000002' and revoked_at is null;
insert into public.user_roles (user_id, role, granted_by)
values ('a1000000-0000-0000-0000-000000000002', 'admin',
  'a1000000-0000-0000-0000-000000000002');

select set_config('request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$select public.submit_guide('Local route', 'George Town', 'Penang',
    'A detailed neighbourhood route submitted for careful admin review.',
    '["Market"]'::jsonb, '["Begin at the main market entrance"]'::jsonb,
    '2 hours')$$,
  'P0001', 'UGC_RULES_ACCEPTANCE_REQUIRED',
  'guide submission requires current UGC consent');
select lives_ok($$select public.accept_current_ugc_rules()$$,
  'tourist accepts current UGC rules');
select lives_ok(
  $$select public.submit_guide('Local route', 'George Town', 'Penang',
    'A detailed neighbourhood route submitted for careful admin review.',
    '["Market"]'::jsonb, '["Begin at the main market entrance"]'::jsonb,
    '2 hours')$$,
  'tourist submits a valid ordered guide');
select is((select count(*) from public.list_my_guide_submissions()), 1::bigint,
  'tourist sees the persisted submission status');
select is((select count(*) from public.published_guides), 0::bigint,
  'pending tourist guide is not public');
select throws_ok(
  $$select public.admin_moderate_guide_revision(
    (select current_revision_id from public.guides where creator_id = auth.uid()),
    'approved', 'Self approval attempt', 1)$$,
  '42501', 'Admin permission required', 'tourist cannot approve own guide');
select throws_ok(
  $$update public.guide_revisions set status = 'approved'
    where author_id = auth.uid()$$,
  '42501', null, 'tourist cannot directly force approval');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from public.guide_revisions where status = 'submitted'),
  1::bigint, 'admin can inspect pending guide submissions');
select lives_ok(
  $$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions where status = 'submitted'),
    'approved', 'Route and stops verified', 1)$$,
  'admin securely approves a guide');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$select public.submit_guide('Second local route', 'Ipoh Old Town', 'Perak',
    'A second complete neighbourhood route submitted for moderation testing.',
    '["Clock tower"]'::jsonb, '["Meet beside the public clock tower"]'::jsonb,
    '90 minutes')$$,
  'tourist can submit another independent guide');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions where title = 'Second local route'),
    'rejected', 'Route needs clearer public access details', 1)$$,
  'admin securely rejects a guide');
select is((select status::text from public.guide_revisions
  where title = 'Second local route'), 'rejected',
  'rejection status persists');
select is((select count(*) from public.published_guides), 1::bigint,
  'rejected guide never becomes public');

reset role;
set local role anon;
select is((select count(*) from public.published_guides), 1::bigint,
  'approved guide becomes publicly browsable');

reset role;
insert into public.spots (id, owner_id) values (
  'a1000000-0000-0000-0000-000000000010',
  'a1000000-0000-0000-0000-000000000001');
insert into public.spot_revisions (
  id, spot_id, revision_number, author_id, status, name, category,
  description, state, city, address, price_range, best_time, things_to_do
) values (
  'a1000000-0000-0000-0000-000000000011',
  'a1000000-0000-0000-0000-000000000010', 1,
  'a1000000-0000-0000-0000-000000000001', 'approved', 'Vote test spot',
  'Park', 'A sufficiently detailed published spot used to test safe upvotes.',
  'Penang', 'George Town', '10 Vote Test Road', '$', 'Morning', 'Walk around'
);
update public.spots set current_revision_id =
  'a1000000-0000-0000-0000-000000000011', approved_revision_id =
  'a1000000-0000-0000-0000-000000000011'
where id = 'a1000000-0000-0000-0000-000000000010';
insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
) values (
  'a1000000-0000-0000-0000-000000000010',
  'a1000000-0000-0000-0000-000000000011', 'Vote test spot', 'Park',
  'A sufficiently detailed published spot used to test safe upvotes.',
  'Penang', 'George Town', '10 Vote Test Road', '$', 'Morning', 'Walk around'
);
select set_config('request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;
select is((public.toggle_spot_upvote(
  'a1000000-0000-0000-0000-000000000010')->>'upvoted')::boolean, true,
  'tourist can upvote a published spot');
select is((select upvote_count from public.published_spots where id =
  'a1000000-0000-0000-0000-000000000010'), 1,
  'displayed upvote count is persisted');
select is((public.toggle_spot_upvote(
  'a1000000-0000-0000-0000-000000000010')->>'upvoted')::boolean, false,
  'second toggle safely removes the duplicate vote');
select is((select count(*) from public.spot_upvotes where spot_id =
  'a1000000-0000-0000-0000-000000000010'), 0::bigint,
  'one-user-per-spot key prevents duplicate votes');

reset role;
insert into public.reviews (
  id, target_type, target_id, user_id, author_display_name, rating, body
) values (
  'a1000000-0000-0000-0000-000000000020', 'spot',
  'a1000000-0000-0000-0000-000000000010',
  'a1000000-0000-0000-0000-000000000002', 'Guide Admin', 4,
  'A useful published review for reaction testing.'
);
insert into public.public_reviews (
  id, target_type, target_id, rating, body, author_display_name, version,
  created_at, updated_at
) select id, target_type, target_id, rating, body, author_display_name, version,
  created_at, updated_at from public.reviews
where id = 'a1000000-0000-0000-0000-000000000020';
select set_config('request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;
select is((public.set_review_vote(
  'a1000000-0000-0000-0000-000000000020', 1)->>'user_vote')::integer, 1,
  'tourist can like another published review');
select is((select likes_count from public.public_reviews where id =
  'a1000000-0000-0000-0000-000000000020'), 1,
  'review like count is persisted');
select is((public.set_review_vote(
  'a1000000-0000-0000-0000-000000000020', -1)->>'user_vote')::integer, -1,
  'one reaction safely changes from like to dislike');
select is((select count(*) from public.review_votes where review_id =
  'a1000000-0000-0000-0000-000000000020'), 1::bigint,
  'review reaction uniqueness prevents duplicate votes');

select * from finish();
rollback;
