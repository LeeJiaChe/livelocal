# Scheduled account and evidence jobs

Status: **GitHub Actions scheduler and Edge worker implemented; production configuration required**

These jobs are privileged operations. Run them from Supabase Cron, a secured
Edge Function scheduler, or another approved backend worker. Never embed or
use the service-role key in Flutter.

## Storage cleanup and account deletion finalizer

GitHub Actions now provides the repository-level scheduler for storage cleanup via `.github/workflows/storage-cleanup-cron.yml`. The scheduled workflow executes automatically at 3:15 AM Malaysia Time (UTC+8 / 19:15 UTC) to avoid GitHub Actions' high-load top-of-the-hour periods.

The workflow executes only after it exists on the repository's default branch. However, scheduled execution alone does not prove remote deployment or configuration success.

### Configuration Prerequisites
Before the workflow can succeed, the `supabase/functions/storage-cleanup` Edge Function must already be deployed to the target environment.

Production/staging secrets must be configured manually in GitHub Actions (via environment or repository secrets). The exact required secret names are:
- `SUPABASE_FUNCTION_URL`: The full URL to the deployed Edge Function.
- `STORAGE_CLEANUP_CRON_SECRET`: Must exactly match the Edge Function's environment secret.

**IMPORTANT:** `SUPABASE_SERVICE_ROLE_KEY` remains strictly inside the Edge Function environment. Do NOT put the service-role key in GitHub Actions.

### Execution and Verification
To verify the setup, operators should run a manual `workflow_dispatch` from the GitHub Actions tab for first-run verification.

Operators verify the first successful run by checking the GitHub Actions logs (which should return a 200 HTTP status) and inspecting the Supabase Edge Function logs to confirm processed/finalized counts.

The worker first calls `public.finalize_due_account_deletions()` to queue known
user-owned objects, claims cleanup jobs, performs copy/delete through the
Supabase Storage API, acknowledges verified outcomes, then calls the finalizer
again. Approved public spot/restaurant media is copied to a random
`retained/` path with platform ownership before database references change and
the user-owned source is deleted. Private and unpublished media is deleted.

The finalizer refuses to delete the auth identity while any Storage object is
still owned by the user or any per-user cleanup job is incomplete. Objects in
an unknown bucket deliberately block finalization for operator review. SQL
never deletes rows from `storage.objects`; direct metadata deletion would
orphan the underlying file.

Before enabling:

- test with representative copies of every owned content state;
- verify storage object cleanup and no identity reconstruction;
- alert on failed jobs, stale processing locks, unknown owned buckets, and due
  deletion requests that remain pending across multiple runs;
- verify retained copies have no `owner_id` and no user identifier in paths;
- confirm the approved deletion/retention policy with legal review;
- export and reconcile due-request counts;
- define operator alerting for partial or failed runs;
- document restoration limits after the grace period.

## Evidence purge

Call `public.purge_expired_moderation_evidence()` daily. The default retention
is read from `app_settings.moderation_evidence_retention_days` and initially
equals 180. Cases on a documented legal hold are excluded.

Before enabling:

- restrict setting changes and hold management to approved operators;
- alert on invalid configuration or sustained zero/abnormal purge counts;
- verify public content is not affected by restricted-evidence purge;
- document the legal-hold release process and audit ownership.

## Deployment rule

Scheduler/function deployment is an external state change and must be
performed only on the explicitly approved staging/production project. Record
project ID, function version, secret rotation owner, schedule, runner identity,
timeout, retry behavior, alert destination, and the first successful run in
the deployment log. Never place `SUPABASE_SERVICE_ROLE_KEY` or the cron secret
in Flutter, source control, logs, or client-visible configuration.
