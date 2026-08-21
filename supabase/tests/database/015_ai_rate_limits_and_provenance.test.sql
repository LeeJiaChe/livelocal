begin;

create extension if not exists pgtap with schema extensions;
select plan(22);

-- 1. Security & RLS checks on ai_generation_usage
select ok(
  (select relrowsecurity from pg_class where oid = 'public.ai_generation_usage'::regclass),
  'ai_generation_usage has RLS enabled'
);

select ok(
  not has_table_privilege('authenticated', 'public.ai_generation_usage', 'select'),
  'authenticated clients cannot read AI generation usage'
);

select ok(
  not has_table_privilege('authenticated', 'public.ai_generation_usage', 'insert'),
  'authenticated clients cannot insert into AI generation usage directly'
);

select ok(
  not has_table_privilege('anon', 'public.ai_generation_usage', 'select'),
  'anonymous clients cannot read AI generation usage'
);

-- 2. Schema check on restaurant_revisions AI provenance
select col_type_is('public', 'restaurant_revisions', 'ai_assisted', 'boolean', 'ai_assisted is boolean');
select col_default_is('public', 'restaurant_revisions', 'ai_assisted', 'false', 'ai_assisted defaults to false');
select col_type_is('public', 'restaurant_revisions', 'ai_source_platform', 'text', 'ai_source_platform is text');

-- 3. Test quota function behavior (with advisory lock)
do $$
declare
  v_user_id uuid := gen_random_uuid();
  v_res jsonb;
  v_usage_id uuid;
begin
  insert into auth.users (id, email)
  values (v_user_id, 'test_quota_1@example.com');

  -- First call: allowed
  v_res := public.check_and_record_ai_generation_quota(
    v_user_id, 'hash_abc123', 'tiktok', 10, 50, 30
  );
  if (v_res->>'allowed')::boolean is not true then
    raise exception 'Expected initial request to be allowed';
  end if;
  v_usage_id := (v_res->>'usage_id')::uuid;

  -- Immediate duplicate with same hash: blocked by cooldown
  v_res := public.check_and_record_ai_generation_quota(
    v_user_id, 'hash_abc123', 'tiktok', 10, 50, 30
  );
  if (v_res->>'allowed')::boolean is not false or v_res->>'error_code' != 'COOLDOWN' then
    raise exception 'Expected duplicate within cooldown to be blocked with COOLDOWN';
  end if;

  -- Different hash: allowed (under hourly limit)
  v_res := public.check_and_record_ai_generation_quota(
    v_user_id, 'hash_def456', 'instagram', 10, 50, 30
  );
  if (v_res->>'allowed')::boolean is not true then
    raise exception 'Expected different hash to be allowed';
  end if;

  -- Record outcome
  perform public.record_ai_generation_outcome(v_usage_id, 'succeeded');
end;
$$;

select pass('Quota check allows first request and blocks immediate duplicate via cooldown');

-- 4. Test hourly quota limit
do $$
declare
  v_user_id uuid := gen_random_uuid();
  v_res jsonb;
  i integer;
begin
  insert into auth.users (id, email)
  values (v_user_id, 'test_quota_2@example.com');

  -- Fill hourly quota (limit = 3 for testing)
  for i in 1..3 loop
    v_res := public.check_and_record_ai_generation_quota(
      v_user_id, 'hash_test_' || i, 'tiktok', 3, 50, 0
    );
    if (v_res->>'allowed')::boolean is not true then
      raise exception 'Expected request % to be allowed', i;
    end if;
  end loop;

  -- 4th request: blocked by hourly limit
  v_res := public.check_and_record_ai_generation_quota(
    v_user_id, 'hash_test_4', 'tiktok', 3, 50, 0
  );
  if (v_res->>'allowed')::boolean is not false or v_res->>'error_code' != 'HOURLY_LIMIT_EXCEEDED' then
    raise exception 'Expected 4th request to be blocked by HOURLY_LIMIT_EXCEEDED, got %', v_res;
  end if;
end;
$$;

select pass('Hourly quota threshold is strictly enforced');

-- 5. Test daily quota limit
do $$
declare
  v_user_id uuid := gen_random_uuid();
  v_res jsonb;
  i integer;
begin
  insert into auth.users (id, email)
  values (v_user_id, 'test_quota_3@example.com');

  -- Fill daily quota (limit = 2 for testing)
  for i in 1..2 loop
    v_res := public.check_and_record_ai_generation_quota(
      v_user_id, 'hash_daily_' || i, 'instagram', 100, 2, 0
    );
    if (v_res->>'allowed')::boolean is not true then
      raise exception 'Expected request % to be allowed', i;
    end if;
  end loop;

  -- 3rd request: blocked by daily limit
  v_res := public.check_and_record_ai_generation_quota(
    v_user_id, 'hash_daily_3', 'instagram', 100, 2, 0
  );
  if (v_res->>'allowed')::boolean is not false or v_res->>'error_code' != 'DAILY_LIMIT_EXCEEDED' then
    raise exception 'Expected 3rd request to be blocked by DAILY_LIMIT_EXCEEDED, got %', v_res;
  end if;
end;
$$;

select pass('Daily quota threshold is strictly enforced');

-- 6. Legacy RPC overload absence
select ok(
  to_regprocedure('public.create_restaurant_draft(text,text,text,text,text,text,text,text,text,double precision,double precision)') is null,
  'legacy 11-param create_restaurant_draft overload does not exist'
);

select ok(
  to_regprocedure('public.save_restaurant_revision_draft(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision)') is null,
  'legacy 12-param save_restaurant_revision_draft overload does not exist'
);

-- 7. Hardened Function ACL checks
select ok(
  not has_function_privilege('anon', 'public.create_restaurant_draft(text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text)', 'execute'),
  'anon role cannot execute create_restaurant_draft'
);

select ok(
  has_function_privilege('authenticated', 'public.create_restaurant_draft(text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text)', 'execute'),
  'authenticated role can execute create_restaurant_draft'
);

select ok(
  not has_function_privilege('anon', 'public.save_restaurant_revision_draft(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text)', 'execute'),
  'anon role cannot execute save_restaurant_revision_draft'
);

select ok(
  has_function_privilege('authenticated', 'public.save_restaurant_revision_draft(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text)', 'execute'),
  'authenticated role can execute save_restaurant_revision_draft'
);

-- 8. AI provenance consistency constraint tests
select lives_ok(
  $$
  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    gen_random_uuid(), 1, gen_random_uuid(), 'Manual Test', '123 St', 'Penang', 'George Town',
    'Malay', '$', 'Laksa', 'https://instagram.com/p/valid1/',
    false, null
  )
  $$,
  'ai_assisted=false and ai_source_platform=null is allowed'
);

select lives_ok(
  $$
  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    gen_random_uuid(), 1, gen_random_uuid(), 'IG Test', '123 St', 'Penang', 'George Town',
    'Malay', '$', 'Laksa', 'https://instagram.com/p/valid2/',
    true, 'instagram'
  )
  $$,
  'ai_assisted=true and ai_source_platform=instagram is allowed'
);

select lives_ok(
  $$
  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    gen_random_uuid(), 1, gen_random_uuid(), 'TikTok Test', '123 St', 'Penang', 'George Town',
    'Malay', '$', 'Laksa', 'https://www.tiktok.com/@creator/video/1234567890123456789',
    true, 'tiktok'
  )
  $$,
  'ai_assisted=true and ai_source_platform=tiktok is allowed'
);

select throws_ok(
  $$
  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    gen_random_uuid(), 1, gen_random_uuid(), 'Invalid Test 1', '123 St', 'Penang', 'George Town',
    'Malay', '$', 'Laksa', 'https://instagram.com/p/valid3/',
    false, 'instagram'
  )
  $$,
  '23514',
  null,
  'ai_assisted=false and non-null ai_source_platform violates constraint'
);

select throws_ok(
  $$
  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    gen_random_uuid(), 1, gen_random_uuid(), 'Invalid Test 2', '123 St', 'Penang', 'George Town',
    'Malay', '$', 'Laksa', 'https://instagram.com/p/valid4/',
    true, null
  )
  $$,
  '23514',
  null,
  'ai_assisted=true and null ai_source_platform violates constraint'
);

select throws_ok(
  $$
  insert into public.restaurant_revisions (
    restaurant_id, revision_number, author_id, name, address, state, city,
    cuisine_type, price_range, reviewed_dishes, social_media_url,
    ai_assisted, ai_source_platform
  ) values (
    gen_random_uuid(), 1, gen_random_uuid(), 'Invalid Test 3', '123 St', 'Penang', 'George Town',
    'Malay', '$', 'Laksa', 'https://instagram.com/p/valid5/',
    true, 'youtube'
  )
  $$,
  '23514',
  null,
  'ai_assisted=true and invalid ai_source_platform violates constraint'
);

select * from finish();
rollback;
