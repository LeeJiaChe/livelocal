-- Fix: published image storage SELECT policies incorrectly resolve
-- unqualified `name` to the subquery table's `name` column instead of
-- storage.objects.name.
--
-- Before (bug):
--   ps.image_path = ps.name       (spot)
--   pr.cover_image_path = pr.name (restaurant)
--
-- After (fix):
--   ps.image_path = objects.name   (spot)
--   pr.cover_image_path = objects.name (restaurant)
--
-- Both published_spots and published_restaurants have a `name` column,
-- so the outer storage.objects.name must be explicitly qualified.

begin;

-- Drop and recreate the spot published-image SELECT policy
drop policy if exists spot_image_select_authorized on storage.objects;
create policy spot_image_select_authorized
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'spot-images'
    and exists (
      select 1
      from public.published_spots ps
      where ps.image_path = objects.name
    )
  );

-- Drop and recreate the restaurant published-image SELECT policy
drop policy if exists restaurant_image_select_published on storage.objects;
create policy restaurant_image_select_published
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'restaurant-images'
    and exists (
      select 1
      from public.published_restaurants pr
      where pr.cover_image_path = objects.name
    )
  );

commit;
