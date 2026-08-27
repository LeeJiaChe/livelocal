begin;

create extension if not exists pgtap with schema extensions;
select plan(30);

select has_table(
  'public', 'review_photos',
  'review photos use a relational table'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.review_photos'::regclass),
  'review_photos has RLS enabled'
);

select col_type_is(
  'public', 'review_photos', 'storage_path', 'text',
  'review photo storage path is text'
);

select col_type_is(
  'public', 'review_photos', 'sort_order', 'smallint',
  'review photo ordering is bounded smallint'
);

select col_type_is(
  'public', 'review_edit_history', 'prior_photo_paths', 'text[]',
  'review edit history records the prior photo set'
);

select is(
  (select file_size_limit from storage.buckets where id = 'review-images'),
  6291456::bigint,
  'review image bucket enforces a 6 MiB object limit'
);

select is(
  (select public from storage.buckets where id = 'review-images'),
  false,
  'review image bucket is private'
);

select ok(
  has_table_privilege('anon', 'public.review_photos', 'select'),
  'anonymous discovery may select rows through the published-review RLS policy'
);

select ok(
  not has_table_privilege('anon', 'public.review_photos', 'insert'),
  'anonymous users cannot insert review photo relationships'
);

select ok(
  not has_table_privilege('authenticated', 'public.review_photos', 'insert'),
  'clients cannot bypass the transactional review photo RPC'
);

select has_function(
  'private', 'enqueue_orphaned_review_uploads', array['interval'],
  'server orphan-upload sweep exists'
);

select ok(
  not has_function_privilege(
    'authenticated',
    'private.enqueue_orphaned_review_uploads(interval)',
    'execute'
  ),
  'mobile clients cannot invoke the orphan-upload sweep'
);

select is(
  (select count(*) from cron.job
   where jobname = 'queue-orphaned-review-images'),
  1::bigint,
  'one daily review upload orphan sweep is scheduled'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid)',
    'execute'
  ),
  'authenticated users can call the review photo RPC'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid)',
    'execute'
  ),
  'anonymous users cannot call the review photo RPC'
);

select has_trigger(
  'public', 'review_photos', 'review_photo_cleanup_after_delete',
  'deleted relationships enqueue physical object cleanup'
);

select has_trigger(
  'public', 'reviews', 'review_photos_remove_when_unpublished',
  'removed or anonymized reviews detach their photos'
);

-- ============================================================
-- Storage Policy Definition Inspections
-- ============================================================

select ok(
  exists (
    select 1 from pg_policy
    where polname = 'review_image_delete_owner'
      and polrelid = 'storage.objects'::regclass
      and polcmd = 'd'
  ),
  'review_image_delete_owner policy exists on storage.objects for DELETE'
);

select ok(
  (select pg_get_expr(polqual, polrelid, true) from pg_policy
   where polname = 'review_image_delete_owner'
     and polrelid = 'storage.objects'::regclass)
  ~ 'review_photos',
  'review_image_delete_owner policy requires object to be UNREFERENCED by review_photos'
);

select ok(
  (select pg_get_expr(polqual, polrelid, true) from pg_policy
   where polname = 'review_image_delete_owner'
     and polrelid = 'storage.objects'::regclass)
  ~ 'auth\.uid',
  'review_image_delete_owner policy requires auth.uid folder prefix match'
);

-- ============================================================
-- Behavioral Tests: Storage RLS & Review Photo Lifecycle
-- ============================================================

-- 1. Setup test users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    'e0000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'photo-owner@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Photo Owner"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'e0000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'photo-stranger@example.test',
    crypt('test-password', gen_salt('bf')), clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Photo Stranger"}'::jsonb,
    clock_timestamp(), clock_timestamp()
  );

-- 2. Setup a published spot target for reviews
insert into public.spots (id) values
  ('e0000000-1000-0000-0000-000000000001');

insert into public.spot_revisions (
  id, spot_id, revision_number, name, category, description, state, city, address,
  price_range, best_time, things_to_do, status
) values (
  'e0000000-1000-0000-0000-000000000011', 'e0000000-1000-0000-0000-000000000001', 1,
  'Penang Botanical Garden', 'Nature', 'Historic park and botanical garden in Penang.',
  'Penang', 'George Town', 'Jalan Kebun Bunga, 10350 George Town', '$',
  'Morning', 'Walking and photography', 'approved'
);

insert into public.published_spots (
  id, revision_id, name, category, description, state, city, address,
  price_range, best_time, things_to_do
) values (
  'e0000000-1000-0000-0000-000000000001',
  'e0000000-1000-0000-0000-000000000011',
  'Penang Botanical Garden', 'Nature', 'Historic park and botanical garden in Penang.',
  'Penang', 'George Town', 'Jalan Kebun Bunga, 10350 George Town', '$',
  'Morning', 'Walking and photography'
);

-- 3. Pre-create storage objects in review-images bucket
insert into storage.objects (bucket_id, name, owner, owner_id)
values
  (
    'review-images',
    'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/failed_upload.jpg',
    'e0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001'
  ),
  (
    'review-images',
    'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg',
    'e0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001'
  );

-- 4. User A (Owner) accepts UGC rules
select set_config(
  'request.jwt.claims',
  '{"sub":"e0000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.accept_current_ugc_rules()$$,
  'owner accepts current UGC rules'
);

-- Owner can SELECT their own unreferenced upload via review_image_select_published_owner_admin
select is(
  (select count(*)::int from storage.objects
   where bucket_id = 'review-images'
     and name = 'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/failed_upload.jpg'),
  1,
  'owner can select their own upload in review-images bucket'
);

-- Anonymous user cannot SELECT unreferenced/unpublished review photo
reset role;
select set_config(
  'request.jwt.claims',
  '{"role":"anon"}',
  true
);
set local role anon;

select is(
  (select count(*)::int from storage.objects
   where bucket_id = 'review-images'
     and name = 'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg'),
  0,
  'anonymous user cannot select unreferenced/unpublished review photo'
);

-- 5. User A submits a review referencing published_photo.jpg
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"e0000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.upsert_review_with_photos(
    'spot',
    'e0000000-1000-0000-0000-000000000001'::uuid,
    5,
    'Beautiful shaded gardens and monkeys everywhere!',
    null,
    array['e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg'],
    'e0000000-2000-0000-0000-000000000001'::uuid
  )$$,
  'owner successfully submits review with photo'
);

reset role;
select is(
  (select count(*) from public.review_photos
   where storage_path = 'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg'),
  1::bigint,
  'public.review_photos references the storage object path'
);

-- Anonymous user CAN now SELECT the published review photo via storage RLS
reset role;
select set_config(
  'request.jwt.claims',
  '{"role":"anon"}',
  true
);
set local role anon;

select is(
  (select count(*)::int from storage.objects
   where bucket_id = 'review-images'
     and name = 'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg'),
  1,
  'anonymous user can select published review photo via RLS'
);

-- 6. User A updates review removing the photo
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"e0000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$select public.upsert_review_with_photos(
    'spot',
    'e0000000-1000-0000-0000-000000000001'::uuid,
    5,
    'Updated review text without any attached photos.',
    1,
    '{}'::text[],
    'e0000000-2000-0000-0000-000000000001'::uuid
  )$$,
  'owner updates review removing the photo'
);

reset role;
select is(
  (select count(*) from public.review_photos
   where review_id = 'e0000000-2000-0000-0000-000000000001'::uuid),
  0::bigint,
  'review_photos relationship is removed on review update'
);

reset role;
select is(
  (select prior_photo_paths from public.review_edit_history
   where review_id = 'e0000000-2000-0000-0000-000000000001'::uuid
   order by created_at desc limit 1),
  array['e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg'],
  'review_edit_history recorded the prior photo path set'
);

select is(
  (select count(*) from private.storage_cleanup_jobs
   where bucket_id = 'review-images'
     and source_path = 'e0000000-0000-0000-0000-000000000001/e0000000-2000-0000-0000-000000000001/published_photo.jpg'
     and action = 'delete'),
  1::bigint,
  'database lifecycle enqueued storage cleanup job for the detached photo'
);

select * from finish();
rollback;
