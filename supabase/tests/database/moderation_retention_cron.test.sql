begin;

create extension if not exists pgtap with schema extensions;
select plan(6);

select has_extension('pg_cron', 'pg_cron extension should exist');

select is(
  (select count(*) from cron.job where jobname = 'purge-moderation-evidence'),
  1::bigint,
  'exactly one purge-moderation-evidence cron job is scheduled'
);

select is(
  (select schedule from cron.job where jobname = 'purge-moderation-evidence'),
  '0 3 * * *',
  'job is scheduled for 3:00 AM daily'
);

select is(
  btrim((select command from cron.job where jobname = 'purge-moderation-evidence')),
  'select public.purge_expired_moderation_evidence();',
  'job command exactly matches expected SQL'
);

select is(
  (select active from cron.job where jobname = 'purge-moderation-evidence'),
  true,
  'job is active'
);

select ok(
  nullif(
    btrim(
      (select username
       from cron.job
       where jobname = 'purge-moderation-evidence')
    ),
    ''
  ) is not null,
  'job has an execution database role'
);

rollback;
