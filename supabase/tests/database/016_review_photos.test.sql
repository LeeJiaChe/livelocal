begin;

create extension if not exists pgtap with schema extensions;
select plan(17);

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

select * from finish();
rollback;
