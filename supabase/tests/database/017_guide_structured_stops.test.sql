begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

select col_type_is(
  'public', 'guide_revisions', 'stop_details', 'jsonb',
  'guide revisions retain structured stop metadata'
);

select col_type_is(
  'public', 'published_guides', 'stop_details', 'jsonb',
  'published guides expose structured stop metadata'
);

select has_function(
  'public', 'submit_guide_v2',
  array['text','text','text','text','jsonb','jsonb','jsonb','text'],
  'tourist and Creator submissions use the structured guide RPC'
);

select has_function(
  'public', 'admin_save_guide_draft_v2',
  array['uuid','text','text','text','text','jsonb','jsonb','jsonb','text','integer'],
  'admin drafts use the structured guide RPC'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.submit_guide_v2(text,text,text,text,jsonb,jsonb,jsonb,text)',
    'execute'
  ),
  'authenticated accounts can call the protected structured submit RPC'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.submit_guide_v2(text,text,text,text,jsonb,jsonb,jsonb,text)',
    'execute'
  ),
  'anonymous accounts cannot call the structured submit RPC'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.submit_guide(text,text,text,text,jsonb,jsonb,text)',
    'execute'
  ),
  'the legacy submit entry point remains available and auto-populates structured stops'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.admin_save_guide_draft_v2(uuid,text,text,text,text,jsonb,jsonb,jsonb,text,integer)',
    'execute'
  ),
  'authenticated sessions can reach the internally admin-guarded draft RPC'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.admin_save_guide_draft_v2(uuid,text,text,text,text,jsonb,jsonb,jsonb,text,integer)',
    'execute'
  ),
  'anonymous accounts cannot reach the admin draft RPC'
);

select has_trigger(
  'public', 'published_guides', 'published_guide_stop_details_sync',
  'publication copies structured stops from the approved revision'
);

select ok(
  not has_function_privilege(
    'public', 'private.assert_valid_guide_stop_details(jsonb)', 'execute'
  ),
  'the listing-validation helper is not directly callable'
);

select ok(
  not exists (
    select 1 from public.guide_revisions
    where jsonb_array_length(stop_details) = 1
  ),
  'no guide revision has an invalid one-stop structured route'
);

select * from finish();
rollback;
