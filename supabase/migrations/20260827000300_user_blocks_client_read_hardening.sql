begin;

-- 1. Remove obsolete client SELECT policy on public.user_blocks
drop policy if exists user_blocks_select_self on public.user_blocks;

-- 2. Revoke all direct table privileges from anon and authenticated client roles
revoke all on table public.user_blocks from public, anon, authenticated;

-- 3. Ensure RPC execution permissions remain strictly for authenticated users
revoke all on function public.block_content_author(text, uuid) from public, anon;
revoke all on function public.unblock_user(uuid) from public, anon;
revoke all on function public.list_my_blocked_users() from public, anon;

grant execute on function public.block_content_author(text, uuid) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;
grant execute on function public.list_my_blocked_users() to authenticated;

commit;
