begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

select has_trigger(
  'public', 'guide_moderation_decisions', 'guide_decision_notification',
  'guide decisions create workflow notifications'
);

select ok(
  not has_function_privilege(
    'authenticated', 'private.notify_guide_decision()', 'execute'
  ),
  'mobile clients cannot invoke the guide notification trigger function'
);

select has_trigger(
  'public', 'moderation_decisions', 'report_decision_notification',
  'report decisions create reporter and applicable author notifications'
);

select ok(
  not has_function_privilege(
    'authenticated', 'private.notify_report_decision()', 'execute'
  ),
  'mobile clients cannot invoke the report notification trigger function'
);

select ok(
  (select relrowsecurity from pg_class
   where oid = 'public.notifications'::regclass),
  'notification history has RLS enabled'
);

select ok(
  not has_table_privilege('authenticated', 'public.notifications', 'insert'),
  'mobile clients cannot manufacture notification events'
);

select ok(
  exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and tablename = 'guide_moderation_decisions'
      and indexdef like 'CREATE UNIQUE INDEX%'
      and indexdef like '%(guide_id, guide_version)%'
  ),
  'one Guide decision row can exist per version'
);

select ok(
  exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and tablename = 'moderation_decisions'
      and indexdef like 'CREATE UNIQUE INDEX%'
      and indexdef like '%(case_id, case_version)%'
  ),
  'one report decision row can exist per case version'
);

select * from finish();
rollback;
