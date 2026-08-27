begin;

-- 1. Security-definer boolean helper to check if a review photo storage path belongs to a published, visible review
create or replace function private.is_public_review_photo(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select exists (
    select 1
    from public.review_photos photo
    join public.public_reviews public_review
      on public_review.id = photo.review_id
    where photo.storage_path = p_storage_path
      and not private.is_content_hidden('review', public_review.id)
      and not private.is_content_author_blocked('review', public_review.id)
  );
$$;

-- 2. Security-definer boolean helper to check if a storage path is referenced by review_photos
create or replace function private.is_review_photo_referenced(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select exists (
    select 1
    from public.review_photos photo
    where photo.storage_path = p_storage_path
  );
$$;

-- 3. Grants for policy evaluation helpers
revoke all on function private.is_public_review_photo(text) from public, anon, authenticated;
grant execute on function private.is_public_review_photo(text) to anon, authenticated;

revoke all on function private.is_review_photo_referenced(text) from public, anon, authenticated;
grant execute on function private.is_review_photo_referenced(text) to anon, authenticated;

-- 4. Recreate review-images storage policies using the safe boolean helpers
drop policy if exists review_image_select_published on storage.objects;
create policy review_image_select_published
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'review-images'
    and private.is_public_review_photo(storage.objects.name)
  );

drop policy if exists review_image_delete_owner on storage.objects;
create policy review_image_delete_owner
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'review-images'
    and (
      owner_id = (select auth.uid())::text
      or owner = (select auth.uid())
      or (storage.foldername(name))[1] = (select auth.uid())::text
    )
    and not private.is_review_photo_referenced(storage.objects.name)
  );

commit;
