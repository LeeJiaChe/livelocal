create extension if not exists pg_cron;

select cron.schedule(
  'purge-moderation-evidence',
  '0 3 * * *',
  $$ select public.purge_expired_moderation_evidence(); $$
);
