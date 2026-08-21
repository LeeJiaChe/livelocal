# Reproducible Supabase backend

This directory is the source of truth for the LiveLocal database. None of
these files were applied to a remote project during this implementation.

## Local verification

Prerequisites: Supabase CLI and a Docker-compatible runtime.

```sh
supabase start
supabase db reset
supabase test db
```

`supabase db reset` is destructive to the currently linked database. Use a
local project ID and confirm `supabase status` before reset. Never link this
workspace to production for local replay.

## Migration order

1. `202608050001_core_identity.sql` — profiles, server-owned roles, access.
2. `202608050002_account_lifecycle.sql` — settings, audit, deletion, appeals,
   admin account access and session revocation.
3. `202608050003_spots_reviews_moderation.sql` — spot revisions, public
   projections, reviews, rating transactions, reports, storage policies.
4. `202608050004_admin_read_models.sql` — restricted admin queues/read models.
5. `202608050005_creators_restaurants_discounts.sql` — creator application,
   restaurant revisions, social allowlist, discounts and public server time.
6. `202608050006_saved_places_itineraries.sql` — private saves, location
   preferences, itinerary ordering and ownership.
7. `202608050007_guides_notifications_operations.sql` — admin guide revisions,
   in-app notifications, statistics/audit, retention and deletion finalizers.
8. `202608050008_workflow_closures.sql` — general content reports, appeals,
   guide archive, creator discount management, concurrency closures.
9. `202608050009_user_safety_blocks.sql` — private server-derived user blocks
   and viewer-specific public-content filtering.
10. `202608050010_spot_image_rights.sql` — server-required spot photo and
    owner image-rights acknowledgement before moderation submission.
11. `202608050011_owner_content_revisions.sql` — current owner submission read
    models, immutable revisions, withdrawal, draft discard, and restaurant
    image-object enforcement.
12. `202608050012_storage_cleanup_lifecycle.sql` — private object-cleanup queue,
    service-only claim/acknowledgement RPCs, retained-media anonymization,
    stricter delete policies, and two-stage account finalization.
13. `202608180001_social_account_connections.sql` — post-only restaurant link
    enforcement plus encrypted, service-owned social OAuth connection storage.

Every application table exposed through the data API has RLS enabled. Flutter
uses only the publishable/anonymous key. Service-role execution belongs only
in a trusted server or scheduled job.

## Tests

`tests/database/` contains ten pgTAP suites. Tests create isolated identities
inside transactions and roll back. They verify guests, tourists, creators,
admins, RLS ownership, direct-write denial, role escalation denial, version
conflicts, report/appeal behavior, and user-block privacy.

The `storage-cleanup` Edge Function is the only production path for queued
physical object deletion/re-homing. It requires both a valid function
invocation JWT and the separately configured `STORAGE_CLEANUP_CRON_SECRET`.
It uses the platform-provided service-role key only inside the server runtime;
that key is never embedded in Flutter. CI type-checks the function with Deno.

## AI restaurant listing import

`generate-restaurant-listing` accepts an authenticated TikTok or Instagram
post/profile URL. It verifies the current database role and active account
state, reads source metadata through official platform APIs, and sends only
that untrusted metadata to a structured-output AI call. Results are transient;
the existing restaurant draft, duplicate-detection, and moderation RPCs remain
the only persistence/publication path.

`social-account-oauth` provides the creator-authorized connection required for
profile imports. OAuth state is hashed, single-use and expires after ten
minutes. Provider tokens are AES-GCM encrypted before they enter the
server-only `social_account_connections` table. Flutter never receives a
provider token or a service-role credential.

Required Edge Function secrets:

- `AI_API_KEY`, `AI_MODEL`, and optionally `AI_API_BASE_URL` for an
  OpenAI-compatible structured-output endpoint.
- `SOCIAL_TOKEN_ENCRYPTION_KEY`, a base64-encoded random 32-byte value.
- `SOCIAL_OAUTH_CALLBACK_URL`, the deployed `social-account-oauth` function
  URL, and optionally `SOCIAL_OAUTH_APP_REDIRECT_URI` (defaults to
  `io.livelocal.app://social-connected`).
- `TIKTOK_CLIENT_KEY` and `TIKTOK_CLIENT_SECRET` for Login Kit plus Display API
  access with `user.info.basic` and `video.list`.
- `INSTAGRAM_CLIENT_ID`, `INSTAGRAM_CLIENT_SECRET`,
  `META_GRAPH_API_VERSION`, and `INSTAGRAM_OEMBED_ACCESS_TOKEN` for Instagram
  Login/API and public post oEmbed metadata. The oEmbed value should be a Meta
  App Access Token (or another token approved for that endpoint).

`AI_MODEL` must support strict `json_schema` response formatting at the
configured `AI_API_BASE_URL`. The model name is deliberately environment-owned
and is not compiled into Flutter or the Edge Function.

Generate the token-encryption secret locally without checking it into Git:

```sh
openssl rand -base64 32
```

Deploy after linking the intended Supabase project:

```sh
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push --dry-run
supabase db push
supabase secrets set --env-file supabase/.env.functions
supabase functions deploy generate-restaurant-listing
supabase functions deploy social-account-oauth --no-verify-jwt
```

The OAuth function deliberately disables gateway JWT verification because
provider callbacks have no LiveLocal bearer token. It authenticates start
requests itself and accepts callbacks only with a valid stored state. Register
the exact `SOCIAL_OAUTH_CALLBACK_URL` in both provider developer consoles.

Provider-console setup:

- TikTok: add Login Kit and Display API to the app, request approval for
  `user.info.basic` and `video.list`, and register the HTTPS Edge Function
  callback as a Web redirect URI. Profile imports only cover the connected
  creator's public videos.
- Meta/Instagram: add **Instagram API with Instagram Login**, request
  `instagram_business_basic`, register the exact HTTPS callback URI, and use a
  professional Creator or Business Instagram account. Move the app to Live
  mode/app review before testing users who are not app roles.
- Configure Instagram oEmbed access if unconnected public post imports are
  required. Private, deleted, age/region-restricted, or otherwise unavailable
  posts return a typed error rather than fabricated listing data.

The official list/oEmbed endpoints expose post metadata and captions, not a
general transcript of video audio or guaranteed on-screen text. This first
version therefore extracts only facts supported by that official metadata; it
does not download or copy social-media video/images into Storage.

CI starts a fresh local Supabase stack, replays every migration, then runs
`supabase test db`. A green Flutter test run does not substitute for this job.

## Required operations

The secured `storage-cleanup` Edge Function and evidence purge must be
scheduled and monitored after an approved deployment. The worker invokes:

- `public.claim_storage_cleanup_jobs(integer)` plus its service-only
  activation/completion/failure handshake;
- `public.finalize_due_account_deletions()`;
- `public.purge_expired_moderation_evidence()`.

See [scheduled jobs](../docs/operations/scheduled-jobs.md). Do not grant either
function to mobile roles or call it from Flutter.
