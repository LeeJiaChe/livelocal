# Unified place identity audit and architecture

Date: 2026-08-29  
Branch baseline: `feature/final-submission-completion` at `23b4e1a210450824611296cf4a30ae7ac22b661e`

## Product invariant

Google provides location truth. LiveLocal provides the local layer.

- **Place** is a real-world destination identity.
- **Eat** is approved LiveLocal food insight attached to a Place.
- **Spot / Things to Do** is approved LiveLocal experiential insight attached to a Place.
- **Guide** is a curated sequence of Places with LiveLocal context.

A Place is either Google-backed (`place_provider = 'google'` plus a stable
`google_place_id`) or LiveLocal custom (provider identity is null and LiveLocal
owns the name, full address, latitude, and longitude).

## Pre-change audit

### Address ownership

| Entity | Address before unification | Coordinates before unification | Provider identity before unification |
|---|---|---|---|
| `spot_revisions`, `published_spots` | Full `address`, plus city/state | `latitude`, `longitude` | None |
| `restaurant_revisions`, `published_restaurants` | Full `address`, plus city/state | `latitude`, `longitude` | None |
| Google external Place | Resolved live as `formattedAddress` | Resolved live | `provider` + Google Place ID in the client |
| `saved_places` | No copied provider address | No copied provider coordinates | `external_provider` + `external_place_id` for external saves |
| Guide structured stops | Listing stops inherited listing data; custom stops held display text | Listing stops inherited listing data; custom stops had no pin | Listing UUID or custom text only |
| `itinerary_items` | Local stop snapshot fields; provider stop resolved separately | Local snapshot or provider resolution | External provider identity supported |

### Missing Google identity

Before this migration, all Spot and Restaurant draft, revision, and published
records lacked `google_place_id`. Creator Google Maps, Instagram, TikTok, and
website extraction could locate a probable Google business, but the stable ID
and coordinates were discarded before draft persistence. Admin approval could
therefore not preserve the match.

### Duplicate paths

Duplicates could occur in four concrete places:

1. Discover rendered a Google result and a separate approved Spot/Eat card for
   the same destination because there was no shared identity.
2. `saved_places` could hold separate `external`, `spot`, and `restaurant`
   rows for the same physical destination.
3. Collections inherited those separate saved identities.
4. Guide custom text, Guide listing UUIDs, and external provider identities
   represented separate location universes.

Legacy Spot/Eat duplicates cannot be deterministically resolved without a
stable identifier. They remain independently discoverable; no fuzzy migration
or hiding is performed.

### Trip full-address loss

`fetch_saved_route_candidates` did not expose an `address` property. The app's
provider-resolution path then placed Google's formatted address into `city`.
This lost the distinction between a usable full address and locality. The new
contract returns `address`; Google results keep live `formattedAddress`, while
custom and legacy content use `published_spots.address` or
`published_restaurants.address`.

### Guide external-place support

Before unification, a structured stop could be a LiveLocal listing UUID or
custom display text only. It could not represent a Google-backed destination.
Provider stops now store the stable provider identity in structured stop JSON.
Existing listing and custom stop shapes remain valid.

### Where “Place” was treated as a content type

- Explore exposed `All / Places / Spots / Eats / Guides`, making Google Places
  a peer content silo.
- Search mixed Google cards with separate Spot/Eat cards.
- Public details separated external Place, Spot, and Restaurant destinations.
- Save state and collection membership keyed those three origins separately.
- Trip candidate rendering branched on content-table origin.
- Contribution forms began by creating a Spot or Restaurant record instead of
  first confirming the real destination.

## Forward architecture

The additive migration adds nullable `place_provider` and `google_place_id` to
both revision and published Spot/Restaurant models. Publication sync copies the
identity from the approved revision. Partial indexes support batched lookup;
partial uniqueness permits at most one approved enrichment per Google identity
within each content type while allowing one Spot and one Eat on the same Place.

`lookup_place_enrichments` accepts at most 20 Google Place IDs and returns only
published Spot/Eat summaries in one call. Discover renders one provider card
and layers those summaries onto it. Provider facts remain live and are not
bulk-copied into Supabase.

New saves normalize linked Spot/Eat records to `google` + `google_place_id`.
Custom and legacy unlinked content retains its LiveLocal UUID. Collection and
route RPCs resolve either form and return both identity and LiveLocal context.

No deployed migration was edited, no startup migration was added, and no
legacy row is fuzzily linked.
