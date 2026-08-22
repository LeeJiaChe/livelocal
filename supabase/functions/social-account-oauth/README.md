# Social Account OAuth (DEFERRED / NOT DEPLOYED)

## Status: DEFERRED

This Edge Function was created as part of teammate PR #52 to prototype creator
OAuth connection with TikTok and Instagram.

### Architecture Notes

- The active LiveLocal product UX is strictly **post-only** (Creators paste
  individual review video/post links, e.g., TikTok video or Instagram Reel).
- Profile-level OAuth import is **deferred** post-MVP.
- This function is **NOT DEPLOYED** on staging or production, and is excluded
  from `supabase/config.toml`.
- Teammate contribution and Git ancestry are fully preserved in the repository
  history.
