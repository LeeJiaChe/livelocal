begin;

create extension if not exists pgtap with schema extensions;
select plan(33);

-- 1. Create Tourist, Creator, and Admin users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000',
   'b1300000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'pipeline-tourist@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Pipeline Tourist"}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('00000000-0000-0000-0000-000000000000',
   'b1300000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'pipeline-creator@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Pipeline Creator"}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('00000000-0000-0000-0000-000000000000',
   'b1300000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'pipeline-admin@example.test', crypt('test-password', gen_salt('bf')),
   clock_timestamp(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{"display_name":"Pipeline Admin"}'::jsonb, clock_timestamp(), clock_timestamp());

-- Assign roles: user 2 = influencer, user 3 = admin. User 1 remains default tourist.
update public.user_roles
set role = 'influencer', granted_by = 'b1300000-0000-0000-0000-000000000003'
where user_id = 'b1300000-0000-0000-0000-000000000002' and revoked_at is null;

update public.user_roles
set role = 'admin', granted_by = 'b1300000-0000-0000-0000-000000000003'
where user_id = 'b1300000-0000-0000-0000-000000000003' and revoked_at is null;

-- Seed storage objects for uploads
insert into storage.objects (bucket_id, name, owner)
values
  ('spot-images', 'b1300000-0000-0000-0000-000000000001/mansion.jpg', 'b1300000-0000-0000-0000-000000000001'),
  ('restaurant-images', 'b1300000-0000-0000-0000-000000000002/hameediyah.jpg', 'b1300000-0000-0000-0000-000000000002'),
  ('restaurant-images', 'b1300000-0000-0000-0000-000000000001/tohsoon.jpg', 'b1300000-0000-0000-0000-000000000001');

-- TEST 1: Tourist flow
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select lives_ok($cmd$select public.accept_current_ugc_rules()$cmd$,
  'tourist accepts current UGC rules');

-- Tourist submits spot draft
select lives_ok(
  $cmd$select public.create_spot_draft(
    'Heritage Mansion', 'Heritage', 'A historic mansion in George Town with intact courtyard.',
    'Pulau Pinang', 'George Town', '128 Muntri Street', '$$', 'Morning', 'Photography, Walk',
    'b1300000-0000-0000-0000-000000000001/mansion.jpg', null, null)$cmd$,
  'tourist can create spot draft');

select lives_ok(
  $cmd$select public.confirm_spot_image_rights(
    (select current_revision_id from public.spots where owner_id = auth.uid())
  )$cmd$,
  'tourist confirms spot image rights');

select lives_ok(
  $cmd$select public.submit_spot_revision(
    (select current_revision_id from public.spots where owner_id = auth.uid()), null
  )$cmd$,
  'tourist submits spot draft for moderation');

-- Tourist submits guide
select lives_ok(
  $cmd$select public.submit_guide(
    'Muntri Street Heritage Walk', 'George Town', 'Pulau Pinang',
    'A scenic morning walk through George Towns heritage quarter.',
    '["Muntri Mansion", "Camera Museum"]'::jsonb,
    '["Start at Muntri Mansion", "Walk 200m east to Camera Museum"]'::jsonb,
    '1 hour')$cmd$,
  'tourist can submit guide');

-- Tourist attempts to submit restaurant -> MUST FAIL with 42501
select throws_ok(
  $cmd$select public.create_restaurant_draft(
    'Penang Nasi Kandar', '120 Chulia Street', 'Pulau Pinang', 'George Town',
    'Nasi Kandar / Indian Muslim', '$', 'Fried chicken, mutton curry',
    'https://www.tiktok.com/@foodie/video/1234567890123456789',
    null, null, null)$cmd$,
  '42501', 'Approved creator role required',
  'tourist is blocked from submitting restaurant draft');

-- TEST 2: Creator flow
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select lives_ok($cmd$select public.accept_current_ugc_rules()$cmd$,
  'creator accepts current UGC rules');

-- Creator submits restaurant draft -> SUCCEEDS
select lives_ok(
  $cmd$select public.create_restaurant_draft(
    'Hameediyah Restaurant', '164 Campbell Street', 'Pulau Pinang', 'George Town',
    'Nasi Kandar / Indian Muslim', '$$', 'Murtabak, Duck Biryani',
    'https://www.tiktok.com/@foodie/video/9876543210987654321',
    'b1300000-0000-0000-0000-000000000002/hameediyah.jpg', null, null)$cmd$,
  'creator can create restaurant draft');

select lives_ok(
  $cmd$select public.submit_restaurant_revision(
    (select current_revision_id from public.restaurants where owner_id = auth.uid()), null
  )$cmd$,
  'creator submits restaurant draft for moderation');

-- Creator submits a guide -> SUCCEEDS
select lives_ok(
  $cmd$select public.submit_guide(
    'Campbell Street Food Trail', 'George Town', 'Pulau Pinang',
    'A legendary culinary route along Campbell Street George Town.',
    '["Hameediyah Restaurant", "Toh Soon Cafe"]'::jsonb,
    '["Start at Hameediyah for Biryani", "Walk 300m west to Toh Soon for toast"]'::jsonb,
    '2 hours')$cmd$,
  'creator can submit a guide');

-- TEST 3: Tourist Creator Application lifecycle & Promotion
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;

-- Tourist saves draft and submits creator application
select lives_ok(
  $cmd$select public.save_influencer_application_draft(
    null, 'Pipeline Tourist', 'tiktok',
    'https://tiktok.com/@touristfoodie', 1200, 'Local food',
    'I create curated Penang food guides and weekly reviews for the community.', true, null
  )$cmd$,
  'tourist saves creator application draft');

select lives_ok(
  $cmd$select public.submit_influencer_application(
    (select id from public.influencer_applications where user_id = auth.uid()), 1
  )$cmd$,
  'tourist submits creator application');

select is((select status::text from public.influencer_applications where user_id = auth.uid()),
  'submitted', 'application is marked submitted');

-- Admin reviews and approves tourist application (real promotion lifecycle)
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$select public.admin_decide_influencer_application(
    (select id from public.influencer_applications where user_id = 'b1300000-0000-0000-0000-000000000001'),
    'approved', 'Active and verified food creator profile', 2)$cmd$,
  'admin approves creator application');

-- Verify role was promoted to influencer
select is(
  (select role from public.user_roles where user_id = 'b1300000-0000-0000-0000-000000000001' and revoked_at is null),
  'influencer', 'tourist role was promoted to influencer');

-- Verify role history contains both revoked tourist row and active influencer row
select is(
  (select count(*) from public.user_roles where user_id = 'b1300000-0000-0000-0000-000000000001'),
  2::bigint, 'promoted user has 2 role rows in history (revoked tourist + active influencer)');

-- TEST 4: Newly promoted creator restaurant & guide submissions with role history
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$select public.create_restaurant_draft(
    'Toh Soon Cafe', '140 Lebuh Campbell', 'Pulau Pinang', 'George Town',
    'Chinese / Kopitiam', '$', 'Charcoal toast, Half boiled eggs',
    'https://www.tiktok.com/@touristfoodie/video/5554443332221110001',
    'b1300000-0000-0000-0000-000000000001/tohsoon.jpg', null, null)$cmd$,
  'newly approved creator can now submit restaurant draft');

-- Promoted creator submits a 2-stop guide
select lives_ok(
  $cmd$select public.submit_guide(
    'Promoted Creator Heritage Walk', 'George Town', 'Pulau Pinang',
    'A curated walk created after achieving creator status.',
    '["Cheong Fatt Tze Mansion", "Pinang Peranakan Mansion"]'::jsonb,
    '["Start at Blue Mansion", "Walk 800m to Peranakan Mansion"]'::jsonb,
    '2 hours')$cmd$,
  'promoted creator can submit a guide');

-- Admin approves Promoted Creator's guide
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions where title = 'Promoted Creator Heritage Walk'),
    'approved', 'High quality route verified', 1)$cmd$,
  'admin approves promoted creator guide');

select is(
  (select author_display_name from public.published_guides where title = 'Promoted Creator Heritage Walk'),
  'Pipeline Tourist',
  'promoted creator guide attribution has author display name');

select is(
  (select author_is_creator from public.published_guides where title = 'Promoted Creator Heritage Walk'),
  true,
  'promoted creator guide attribution has author_is_creator = true despite revoked tourist history');

-- TEST 5: Revoked Creator (active Tourist) MUST NOT receive Creator badge
-- Admin revokes Creator 2 influencer role and restores tourist
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$
  update public.user_roles
  set revoked_at = clock_timestamp(), revoked_by = auth.uid()
  where user_id = 'b1300000-0000-0000-0000-000000000002' and revoked_at is null;
  insert into public.user_roles (user_id, role, granted_by)
  values ('b1300000-0000-0000-0000-000000000002', 'tourist', auth.uid());
  $cmd$,
  'admin revokes influencer role and restores tourist role for user 2');

-- Demoted user 2 submits a guide as tourist
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$select public.submit_guide(
    'Demoted User Sunset Trail', 'Batu Ferringhi', 'Pulau Pinang',
    'A scenic beach route submitted after role change to tourist.',
    '["Batu Ferringhi Beach", "Miami Beach Penang"]'::jsonb,
    '["Start at Batu Ferringhi Beach", "Walk 1km south to Miami Beach"]'::jsonb,
    '1.5 hours')$cmd$,
  'demoted user submits guide');

-- Admin approves demoted user's guide
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000003","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions where title = 'Demoted User Sunset Trail'),
    'approved', 'Route verified for publication', 1)$cmd$,
  'admin approves demoted user guide');

select is(
  (select author_is_creator from public.published_guides where title = 'Demoted User Sunset Trail'),
  false,
  'demoted user guide has author_is_creator = false because active role is tourist');

-- TEST 6: Moderation & Attribution verification for other submissions
-- Admin approves Creator's Campbell Street guide
select lives_ok(
  $cmd$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions where title = 'Campbell Street Food Trail'),
    'approved', 'High quality route verified', 1)$cmd$,
  'admin approves Campbell Street guide');

select is(
  (select author_display_name from public.published_guides where title = 'Campbell Street Food Trail'),
  'Pipeline Creator',
  'creator guide attribution has author display name');

select is(
  (select author_is_creator from public.published_guides where title = 'Campbell Street Food Trail'),
  false,
  'creator guide approved after demotion correctly receives author_is_creator = false');

-- Admin approves Spot draft
select lives_ok(
  $cmd$select public.admin_moderate_spot_revision(
    (select current_revision_id from public.spots where owner_id = 'b1300000-0000-0000-0000-000000000001'),
    'approved', 'Verified location and photo', 1)$cmd$,
  'admin approves spot draft');

select is((select count(*) from public.published_spots where name = 'Heritage Mansion'),
  1::bigint, 'spot is published');

-- Admin approves Restaurant draft
select lives_ok(
  $cmd$select public.admin_moderate_restaurant_revision(
    (select current_revision_id from public.restaurants where owner_id = 'b1300000-0000-0000-0000-000000000002'),
    'approved', 'Verified video and dishes', 1)$cmd$,
  'admin approves restaurant draft');

select is((select count(*) from public.published_restaurants where name = 'Hameediyah Restaurant'),
  1::bigint, 'restaurant is published');

-- Verify non-admin cannot access admin moderation
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000002","role":"authenticated"}', true);
set local role authenticated;

select throws_ok(
  $cmd$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions limit 1),
    'approved', 'Unauthorized attempt', 1)$cmd$,
  '42501', 'Admin permission required',
  'non-admin cannot moderate guides');

select * from finish();
rollback;
