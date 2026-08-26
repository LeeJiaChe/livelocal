-- Forward ACL hardening for v2 Guide RPCs:
-- Explicitly revoke execute privileges from public and anon roles,
-- and re-grant execute only to authenticated callers.

revoke execute on function public.submit_guide_v2(
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  jsonb,
  text
) from public, anon;

grant execute on function public.submit_guide_v2(
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  jsonb,
  text
) to authenticated;

revoke execute on function public.admin_save_guide_draft_v2(
  uuid,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  jsonb,
  text,
  integer
) from public, anon;

grant execute on function public.admin_save_guide_draft_v2(
  uuid,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  jsonb,
  text,
  integer
) to authenticated;
