# LiveLocal full completion contract

Status: **implementation contract**

Created: 2026-08-26

## Baseline and delivery constraints

- Confirmed `develop` baseline: `b45e76226b5d9b7ee495ff8f2c4a4cda050daeba`
  (`Merge pull request #61 from LeeJiaChe/feature/harden-ai-restaurant-experience`).
- `d0e4b29df7109f5889849d69266d02c091d73762` is already in that baseline; the
  trees at `d0e4b29` and `b45e762` were identical before this overhaul.
- Implementation branch: `feature/full-livelocal-completion`, created from
  `b45e762` with the preserved completion working tree.
- The branch and working tree were corrected and preserved externally. In this
  execution sandbox `.git` remains read-only, so implementation commits cannot
  be created here; push and PR creation remain separate delivery actions and
  are not silently claimed.
- No existing user-facing capability may be removed or made unreachable
  without owner approval. No removals are proposed by this contract.

## Product source of truth

The normative order is:

1. `docs/product/product-behaviour-spec.md`;
2. `docs/product/revised-requirements.md` and the safe interpretation of
   FR01-FR64;
3. this completion brief, including the newly approved review-photo scope;
4. current implemented behavior where it does not conflict with the above.

Supabase remains authoritative. Demo adapters remain explicit test/demo
fixtures and must never become a staging or production fallback.

## Preservation matrix

| Capability present at baseline | Roles | Preservation requirement |
|---|---|---|
| Public approved Spot, Restaurant, Guide, rating, and review discovery | Guest+ | Keep reachable without authentication, with list-first loading/error/empty states |
| Email registration, verification/resend, login, session restore, logout, password reset | Guest/account | Preserve safe account-state gates and protected return intent |
| Profile editing, avatar, legal/support links, deletion request/recovery, appeals | Tourist/Creator/Admin where applicable | Preserve allowlisted edits and server-authoritative account enforcement |
| Spot search, category/state/city/price filters, map context, detail, upvotes | Guest+ / writes signed-in | Preserve all filters, detail actions, and honest location behavior |
| Spot draft, photo, image-rights confirmation, duplicate result, submit, revise, withdraw | Tourist/Creator | Preserve the entire revision pipeline and published-version continuity |
| LocalEats discovery, filters, restaurant detail, social review link | Guest+ | Preserve approved-only public projection and link disclosure |
| Creator application draft/submission/admin decision | Tourist/Admin | Preserve atomic role grant, history, and notification |
| Restaurant manual and AI-assisted draft, image, duplicate result, submit/revise | Creator | Preserve manual fallback and editable AI output; AI never submits or publishes |
| Creator-owned discount lifecycle | Creator/Public/Admin | Preserve owner scope, terms, dates, server-time validity, and disclaimer |
| Saved places and named collections | Tourist/Creator | Preserve create/rename/delete collection, save/move/remove, filter, map, persistence |
| Suggested itineraries and ordered stops | Tourist/Creator | Preserve manual origin, unresolved-place explanation, reorder, persistence, no optimality claim |
| Public Guides and ordered Guide detail | Guest+ | Preserve browse/filter/detail flow |
| Tourist/Creator Guide drafts, ordered listing stops, submit/revise | Tourist/Creator | Preserve and extend with clearly labelled custom stops |
| Admin-created/curated Guide drafts | Admin | Preserve within operational workspace |
| Review rating/text, own edit/delete, like/dislike, report/hide, block | Tourist/Creator | Preserve and extend with 1-3 owned photos |
| Private paginated notification history and read state | Tourist/Creator/Admin where generated | Preserve global bell/history and safe destinations |
| Admin moderation for submissions, creator applications, reports, appeals, access, users, audit | Admin | Preserve all actions in a focused, responsive operations workspace |
| Explicit demo personas/data | Development/test | Preserve explicit demo selection and visible DEMO banner only |

## Final role and navigation contract

Database `influencer` remains an internal compatibility value. Every visible
label is `Creator`.

| Role | Default experience | Primary navigation |
|---|---|---|
| Guest | Discovery-first public home | Home / Explore / Guides / Profile |
| Tourist | Explorer Home with discovery, planning continuation, saves, trips, contribution status, and Guides | Home / Explore / Saved / Trips / Profile |
| Creator | Tourist discovery plus contribution pipeline | Home / Explore / Studio / Saved / Profile |
| Admin mobile | Operational Admin Workspace only | Overview / Review Queue / Content / Users / More |
| Admin wide | Same information architecture in a rail/sidebar | Overview / Review Queue / Content / Users / More |

Notifications use a global bell and dedicated history, never a bottom-nav
destination. Admin public preview is secondary and must not put discovery
content into Admin Overview.

## Screen inventory and target ownership

### Shared/account

- Configuration failure, session loading/failure, welcome, login,
  registration, email verification, password reset, new password, restricted
  account, deletion recovery, appeal, Profile, edit profile, notifications,
  blocked users, legal/support destinations.

### Public discovery

- Guest/Explorer Home, Explore, Spot discovery/detail, LocalEats
  discovery/detail, Guides discovery/detail, public review gallery, public
  preview from Admin.

### Tourist planning and contribution

- Saved, collection detail, save-to-collection sheet, Trips, itinerary detail,
  Spot contribution, Guide builder/preview, My contributions/status.

### Creator Studio

- Studio overview; Spot, Restaurant, and Guide pipelines; AI Restaurant
  Import; restaurant editor; discount manager; draft, pending, needs-changes,
  rejected, and published views.

### Admin Workspace

- Overview; Review Queue for Spots, Restaurants, Guides, Creator
  applications, reports, and appeals; Content; Users/account access; More;
  Audit History; Guide editor; moderation reason/access dialogs; public
  preview entry.

## Shared experience contract

- LiveLocal remains a trustworthy local guide: restrained deep green, warm
  neutral surfaces, real local photography, readable hierarchy, 8-point
  spacing, at least 48x48 touch targets, accessible contrast, and restrained
  motion.
- Tourist layouts are editorial and visual; Creator layouts are status and
  pipeline oriented; Admin layouts are denser and operational.
- Shared controls use one typography, spacing, radius, form, button, status,
  image, loading, empty, error, success, and navigation grammar.
- English and natural Bahasa Malaysia are both complete product locales.
  Place, business, person, platform, code, and technical identifier names are
  not translated.
- Raw backend messages are always mapped to safe localized product copy.

## Review-photo contract

- A review accepts 1-3 optional JPEG, PNG, or WebP images.
- Client selection validates count, MIME/extension, and a 6 MiB source-file
  limit and resizes/compresses before upload where supported.
- Object paths are owner scoped:
  `<auth.uid()>/<review-id>/<random>.<ext>`.
- Database rows relate photos to a review with stable ordering. Public reads
  expose only photos belonging to published reviews.
- Owners can add/remove photos during an expected-version edit. Failed review
  saves clean up new uploads; successful replacement cleans removed objects.
- Review deletion and account cleanup enqueue or perform physical object
  cleanup so uploads are not orphaned.
- Admin report context includes the review photos that were visible for the
  reported revision.

## End-to-end acceptance matrix

| Workflow | Required chain |
|---|---|
| Tourist Spot | draft -> validated photo/rights/duplicate handling -> submit -> admin queue -> decision/notification -> approved public projection -> owner revision while old revision remains public -> new decision/public update |
| Creator application | tourist draft/submit -> admin queue -> atomic approve -> role refresh -> Creator Studio -> notification |
| Creator Restaurant | manual or authenticated Gemini import -> editable draft/photo/duplicate handling -> submit -> admin queue -> decision/notification -> LocalEats -> revision |
| Guide | tourist/Creator draft -> ordered approved and custom stops -> preview -> submit -> admin moderation -> notification -> public Guide -> revision |
| Review | rating/text/0-3 photos -> transactional publish/aggregate -> edit photo add/remove -> reaction -> report/block -> admin decision -> aggregate and notification where applicable |
| Save/Trip | save Spot/Restaurant -> collection -> create trip/manual origin -> reorder -> persist -> reload -> unavailable target remains explained |
| Discount | approved owned Restaurant -> draft/schedule -> server-time active -> pause/revoke/expire -> public disclaimer and visibility update |
| Notification | typed idempotent trigger -> private paginated history -> safe destination validation -> mark read |

## QA and evidence rules

- Stable staging personas: Tourist A, Tourist B, Creator A, Creator B, Admin.
  Credentials are provisioned outside Git and are never documented as
  plaintext.
- QA records use explicit metadata/identifiers and never destructively reset
  unrelated staging content.
- Visible place fixtures remain verified real Malaysian entities, with source
  evidence maintained in `docs/staging_seed_sources.md`.
- Unit/widget/pgTAP/static checks do not substitute for authenticated staging
  evidence. Any unexecuted migration, deployment, provider call, or complete
  workflow remains labelled unverified.

## No-removal decision

No current user-facing capability is proposed for removal or reduction. Legacy
internal duplication may be consolidated only after characterization proves
that the complete user-facing behavior remains reachable.
