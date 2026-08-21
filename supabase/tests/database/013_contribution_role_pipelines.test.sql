begin;

create extension if not exists pgtap with schema extensions;
select plan(21);

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

-- Assign roles: creator = influencer, admin = admin
update public.user_roles
set role = 'influencer', granted_by = 'b1300000-0000-0000-0000-000000000003'
where user_id = 'b1300000-0000-0000-0000-000000000002' and revoked_at is null;

update public.user_roles
set role = 'admin', granted_by = 'b1300000-0000-0000-0000-000000000003'
where user_id = 'b1300000-0000-0000-0000-000000000003' and revoked_at is null;

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
    'https://images.example.test/mansion.jpg', true, 'image/jpeg', 102400)$cmd$,
  'tourist can submit spot draft');

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
    'https://images.example.test/kandar.jpg', 'image/jpeg', 102400)$cmd$,
  '42501', 'Influencer permission required',
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
    'https://images.example.test/hameediyah.jpg', 'image/jpeg', 204800)$cmd$,
  'creator can submit restaurant draft');

-- Creator submits a guide -> SUCCEEDS
select lives_ok(
  $cmd$select public.submit_guide(
    'Campbell Street Food Trail', 'George Town', 'Pulau Pinang',
    'A legendary culinary route along Campbell Street George Town.',
    '["Hameediyah Restaurant", "Toh Soon Cafe"]'::jsonb,
    '["Start at Hameediyah for Biryani", "Walk 300m west to Toh Soon for toast"]'::jsonb,
    '2 hours')$cmd$,
  'creator can submit a guide');

-- TEST 3: Tourist Creator Application lifecycle
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

-- Admin reviews and approves tourist application
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
select is((select role from public.user_roles where user_id = 'b1300000-0000-0000-0000-000000000001' and revoked_at is null),
  'influencer', 'tourist role was promoted to influencer');

-- TEST 4: Newly approved creator can now submit restaurant
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000001","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $cmd$select public.create_restaurant_draft(
    'Toh Soon Cafe', '140 Lebuh Campbell', 'Pulau Pinang', 'George Town',
    'Chinese / Kopitiam', '$', 'Charcoal toast, Half boiled eggs',
    'https://www.tiktok.com/@touristfoodie/video/5554443332221110001',
    'https://images.example.test/tohsoon.jpg', 'image/jpeg', 102400)$cmd$,
  'newly approved creator can now submit restaurant draft');

-- TEST 5: Admin Moderation & Attribution verification
reset role;
select set_config('request.jwt.claims',
  '{"sub":"b1300000-0000-0000-0000-000000000003","role":"authenticated"}', true);
set local role authenticated;

-- Admin approves Creator's Campbell Street guide
select lives_ok(
  $cmd$select public.admin_moderate_guide_revision(
    (select id from public.guide_revisions where title = 'Campbell Street Food Trail'),
    'approved', 'High quality route verified', 1)$cmd$,
  'admin approves Campbell Street guide');

-- Verify published guide attribution: author name & creator badge
select is(
  (select author_display_name from public.published_guides where title = 'Campbell Street Food Trail'),
  'Pipeline Creator',
  'creator guide attribution has author display name');

select is(
  (select author_is_creator from public.published_guides where title = 'Campbell Street Food Trail'),
  true,
  'creator guide attribution has author_is_creator = true');

-- Admin approves Spot draft
select lives_ok(
  $cmd$select public.admin_moderate_spot_revision(
    (select id from public.spot_revisions where name = 'Heritage Mansion'),
    'approved', 'Verified location and photo', 1)$cmd$,
  'admin approves spot draft');

select is((select count(*) from public.published_spots where name = 'Heritage Mansion'),
  1::bigint, 'spot is published');

-- Admin approves Restaurant draft
select lives_ok(
  $cmd$select public.admin_moderate_restaurant_revision(
    (select id from public.restaurant_revisions where name = 'Hameediyah Restaurant'),
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
