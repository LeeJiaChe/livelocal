-- Keep authenticated workflow RPCs out of the anonymous Data API surface.
-- list_active_discounts(uuid) is intentionally excluded because approved
-- offers are part of public Restaurant discovery.

begin;

revoke execute on function public.admin_moderate_guide_revision(
  uuid, text, text, integer
) from public, anon;
revoke execute on function public.create_saved_collection(text, text)
  from public, anon;
revoke execute on function public.delete_saved_collection(uuid)
  from public, anon;
revoke execute on function public.fetch_collection_places(uuid)
  from public, anon;
revoke execute on function public.fetch_saved_route_candidates(uuid)
  from public, anon;
revoke execute on function public.list_my_guide_submissions()
  from public, anon;
revoke execute on function public.list_my_saved_collections()
  from public, anon;
revoke execute on function public.rename_saved_collection(uuid, text, text)
  from public, anon;
revoke execute on function public.set_place_collections(text, uuid, uuid[])
  from public, anon;
revoke execute on function public.set_review_vote(uuid, integer)
  from public, anon;
revoke execute on function public.submit_guide(
  text, text, text, text, jsonb, jsonb, text
) from public, anon;
revoke execute on function public.toggle_spot_upvote(uuid)
  from public, anon;

-- This is a trigger implementation, not a client RPC.
revoke execute on function public.check_saved_collection_item_ownership()
  from public, anon, authenticated;

grant execute on function public.admin_moderate_guide_revision(
  uuid, text, text, integer
) to authenticated;
grant execute on function public.create_saved_collection(text, text)
  to authenticated;
grant execute on function public.delete_saved_collection(uuid)
  to authenticated;
grant execute on function public.fetch_collection_places(uuid)
  to authenticated;
grant execute on function public.fetch_saved_route_candidates(uuid)
  to authenticated;
grant execute on function public.list_my_guide_submissions()
  to authenticated;
grant execute on function public.list_my_saved_collections()
  to authenticated;
grant execute on function public.rename_saved_collection(uuid, text, text)
  to authenticated;
grant execute on function public.set_place_collections(text, uuid, uuid[])
  to authenticated;
grant execute on function public.set_review_vote(uuid, integer)
  to authenticated;
grant execute on function public.submit_guide(
  text, text, text, text, jsonb, jsonb, text
) to authenticated;
grant execute on function public.admin_save_guide_draft(
  uuid, text, text, text, text, jsonb, jsonb, text, integer
) to authenticated;
grant execute on function public.admin_save_guide_draft_v2(
  uuid, text, text, text, text, jsonb, jsonb, jsonb, text, integer
) to authenticated;
grant execute on function public.submit_guide_v2(
  text, text, text, text, jsonb, jsonb, jsonb, text
) to authenticated;
grant execute on function public.toggle_spot_upvote(uuid)
  to authenticated;

commit;
