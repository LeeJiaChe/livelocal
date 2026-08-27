begin;

-- 1. Revoke direct public/client table access from public.review_photos
revoke all on table public.review_photos from public, anon, authenticated;

-- Drop obsolete public/owner read policies on review_photos
drop policy if exists review_photos_public_read on public.review_photos;
drop policy if exists review_photos_owner_read on public.review_photos;

-- Admin read policy can remain for admin dashboards
drop policy if exists review_photos_admin_read on public.review_photos;
create policy review_photos_admin_read
  on public.review_photos for select to authenticated
  using (private.is_admin());

-- 2. Create privacy-safe public read RPC for visible review photos
create or replace function public.list_public_review_photos(
  p_review_ids uuid[]
)
returns table (
  review_id uuid,
  storage_path text,
  sort_order smallint
)
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select
    photo.review_id,
    photo.storage_path,
    photo.sort_order
  from public.review_photos photo
  join public.public_reviews public_review
    on public_review.id = photo.review_id
  where photo.review_id = any(p_review_ids)
    and not private.is_content_hidden('review', public_review.id)
    and not private.is_content_author_blocked('review', public_review.id)
  order by photo.review_id, photo.sort_order, photo.id;
$$;

revoke all on function public.list_public_review_photos(uuid[]) from public, anon, authenticated;
grant execute on function public.list_public_review_photos(uuid[]) to anon, authenticated;

-- 3. Update Storage RLS policies on review-images bucket to support opaque path 'reviews/<reviewId>/<photoId>.<ext>'
drop policy if exists review_image_insert_owner on storage.objects;
create policy review_image_insert_owner
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'review-images'
    and private.can_use_protected_features()
    and (
      name ~ '^reviews/[0-9a-fA-F-]{36}/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'
      or (storage.foldername(name))[1] = (select auth.uid())::text
    )
  );

drop policy if exists review_image_select_published on storage.objects;
create policy review_image_select_published
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'review-images'
    and exists (
      select 1
      from public.review_photos photo
      join public.public_reviews public_review
        on public_review.id = photo.review_id
      where photo.storage_path = storage.objects.name
        and not private.is_content_hidden('review', public_review.id)
        and not private.is_content_author_blocked('review', public_review.id)
    )
  );

drop policy if exists review_image_select_owner_admin on storage.objects;
create policy review_image_select_owner_admin
  on storage.objects for select to authenticated
  using (
    bucket_id = 'review-images'
    and (
      owner_id = (select auth.uid())::text
      or owner = (select auth.uid())
      or (storage.foldername(storage.objects.name))[1] = (select auth.uid())::text
      or private.is_admin()
    )
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
    and not exists (
      select 1
      from public.review_photos photo
      where photo.storage_path = storage.objects.name
    )
  );

-- 4. Update upsert_review_with_photos to validate opaque paths and forbid user-ID paths for anonymous reviews
create or replace function public.upsert_review_with_photos(
  p_target_type text,
  p_target_id uuid,
  p_rating integer,
  p_body text,
  p_expected_version integer,
  p_photo_paths text[],
  p_new_review_id uuid,
  p_is_anonymous boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
declare
  existing public.reviews;
  saved public.reviews;
  author_name text;
  selected_review_id uuid;
  photo_path text;
  prior_paths text[] := '{}';
  effective_anonymous boolean := coalesce(p_is_anonymous, false);
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot write reviews';
  end if;
  perform private.assert_current_ugc_rules_accepted();
  perform private.assert_no_banned_words(p_body);

  if (p_target_type = 'spot' and not exists (
        select 1 from public.published_spots where id = p_target_id
      ))
      or (p_target_type = 'restaurant' and not exists (
        select 1 from public.published_restaurants where id = p_target_id
      ))
      or p_target_type not in ('spot', 'restaurant') then
    raise exception using errcode = '23503', message = 'Review target is unavailable';
  end if;
  if p_rating not between 1 and 5
      or char_length(btrim(p_body)) not between 3 and 2000 then
    raise exception using errcode = '22023', message = 'Invalid review';
  end if;
  if cardinality(coalesce(p_photo_paths, '{}')) > 3
      or cardinality(coalesce(p_photo_paths, '{}')) < 0
      or cardinality(coalesce(p_photo_paths, '{}')) <>
        cardinality(array(select distinct unnest(coalesce(p_photo_paths, '{}')))) then
    raise exception using errcode = '22023', message = 'Invalid review photos';
  end if;

  select p.display_name into author_name
  from public.profiles p where p.id = auth.uid();

  select * into existing from public.reviews
  where user_id = auth.uid()
    and target_type = p_target_type
    and target_id = p_target_id
    and status = 'published'
  for update;

  if found then
    selected_review_id := existing.id;
    if p_expected_version is null or existing.version <> p_expected_version then
      raise exception using errcode = '40001', message = 'Review changed concurrently';
    end if;
  else
    if p_expected_version is not null then
      raise exception using errcode = 'P0002', message = 'Review not found';
    end if;
    selected_review_id := coalesce(p_new_review_id, gen_random_uuid());
  end if;

  foreach photo_path in array coalesce(p_photo_paths, '{}') loop
    -- Validate path format
    if photo_path !~ (
          '^reviews/' || selected_review_id::text ||
          '/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'
        )
        and photo_path !~ (
          '^' || auth.uid()::text || '/' || selected_review_id::text ||
          '/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'
        ) then
      raise exception using errcode = '22023', message = 'Invalid review photo';
    end if;

    -- Strict privacy rule: Anonymous reviews must NEVER use a path containing user ID
    if effective_anonymous and photo_path ~ ('^' || auth.uid()::text || '/') then
      raise exception using errcode = '22023', message = 'Anonymous review photos must use privacy-safe storage paths';
    end if;

    -- Must exist in review-images bucket and belong to current user
    if not exists (
      select 1 from storage.objects object
      where object.bucket_id = 'review-images'
        and object.name = photo_path
        and (
          object.owner_id = auth.uid()::text
          or object.owner = auth.uid()
          or (storage.foldername(object.name))[1] = auth.uid()::text
        )
    ) then
      raise exception using errcode = '22023', message = 'Invalid review photo';
    end if;
  end loop;

  if existing.id is not null then
    select coalesce(array_agg(photo.storage_path order by photo.sort_order), '{}')
    into prior_paths
    from public.review_photos photo
    where photo.review_id = existing.id;

    insert into public.review_edit_history (
      review_id, prior_rating, prior_body, prior_version, edited_by,
      prior_photo_paths
    ) values (
      existing.id, existing.rating, existing.body, existing.version,
      auth.uid(), prior_paths
    );
    update public.reviews
    set rating = p_rating,
        body = btrim(p_body),
        author_display_name = author_name,
        is_anonymous = effective_anonymous,
        version = version + 1,
        updated_at = clock_timestamp()
    where id = existing.id
    returning * into saved;
  else
    insert into public.reviews (
      id, user_id, target_type, target_id, rating, body, author_display_name,
      is_anonymous
    ) values (
      selected_review_id, auth.uid(), p_target_type, p_target_id, p_rating,
      btrim(p_body), author_name, effective_anonymous
    ) returning * into saved;
  end if;

  delete from public.review_photos photo
  where photo.review_id = saved.id
    and not (photo.storage_path = any(coalesce(p_photo_paths, '{}')));

  insert into public.review_photos (
    review_id, owner_id, storage_path, sort_order
  )
  select saved.id, auth.uid(), path, (ordinality - 1)::smallint
  from unnest(coalesce(p_photo_paths, '{}')) with ordinality as selected(path, ordinality)
  on conflict (storage_path) do update
  set sort_order = excluded.sort_order;

  insert into public.public_reviews (
    id, target_type, target_id, rating, body, author_display_name,
    is_anonymous, version, created_at, updated_at
  ) values (
    saved.id, saved.target_type, saved.target_id, saved.rating, saved.body,
    case when saved.is_anonymous then 'Anonymous' else saved.author_display_name end,
    saved.is_anonymous, saved.version, saved.created_at, saved.updated_at
  ) on conflict (id) do update set
    rating = excluded.rating,
    body = excluded.body,
    author_display_name = case when excluded.is_anonymous then 'Anonymous' else saved.author_display_name end,
    is_anonymous = excluded.is_anonymous,
    version = excluded.version,
    updated_at = excluded.updated_at;

  perform private.recalculate_target_rating(p_target_type, p_target_id);
  return (to_jsonb(saved) - 'user_id') || jsonb_build_object(
    'photo_paths', coalesce(p_photo_paths, '{}'),
    'author_display_name', case when saved.is_anonymous then 'Anonymous' else saved.author_display_name end,
    'is_anonymous', saved.is_anonymous
  );
end;
$$;

-- 5. Update backward compatibility wrapper
create or replace function public.upsert_review_with_photos(
  p_target_type text,
  p_target_id uuid,
  p_rating integer,
  p_body text,
  p_expected_version integer,
  p_photo_paths text[],
  p_new_review_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
begin
  return public.upsert_review_with_photos(
    p_target_type,
    p_target_id,
    p_rating,
    p_body,
    p_expected_version,
    p_photo_paths,
    p_new_review_id,
    false
  );
end;
$$;

-- 6. Update orphan cleanup to support opaque paths
create or replace function private.enqueue_orphaned_review_uploads(
  p_older_than interval default interval '24 hours'
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
declare
  orphan storage.objects%rowtype;
  queued_count integer := 0;
begin
  if p_older_than < interval '1 hour' then
    raise exception using errcode = '22023',
      message = 'Review upload grace period must be at least one hour';
  end if;

  for orphan in
    select object.*
    from storage.objects object
    where object.bucket_id = 'review-images'
      and object.created_at < clock_timestamp() - p_older_than
      and not exists (
        select 1 from public.review_photos photo
        where photo.storage_path = object.name
      )
  loop
    perform private.enqueue_storage_cleanup(
      coalesce(
        case when orphan.owner_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then orphan.owner_id::uuid else null end,
        private.storage_path_owner(orphan.name)
      ),
      'review-images',
      orphan.name,
      'delete',
      'review_upload_orphaned'
    );
    queued_count := queued_count + 1;
  end loop;
  return queued_count;
end;
$$;

-- 7. Ensure execution grants
revoke all on function public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid,boolean) from public, anon;
grant execute on function public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid,boolean) to authenticated;

revoke all on function public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid) from public, anon;
grant execute on function public.upsert_review_with_photos(text,uuid,integer,text,integer,text[],uuid) to authenticated;

commit;
