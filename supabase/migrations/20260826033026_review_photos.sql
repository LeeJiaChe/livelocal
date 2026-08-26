begin;

-- Review media is private-by-default Storage content. Public access is
-- granted only while the related review remains in the public projection.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'review-images', 'review-images', false, 6291456,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create table public.review_photos (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews(id) on delete cascade,
  owner_id uuid references auth.users(id) on delete set null,
  storage_path text not null unique
    check (char_length(storage_path) between 10 and 1024),
  sort_order smallint not null check (sort_order between 0 and 2),
  created_at timestamptz not null default clock_timestamp()
);

create index review_photos_review_order_idx
  on public.review_photos(review_id, sort_order, id);

alter table public.review_edit_history
  add column prior_photo_paths text[] not null default '{}';

alter table public.review_photos enable row level security;

create policy review_photos_public_read
  on public.review_photos for select to anon, authenticated
  using (
    exists (
      select 1
      from public.public_reviews public_review
      where public_review.id = review_id
        and not private.is_content_hidden('review', public_review.id)
    )
  );

create policy review_photos_owner_read
  on public.review_photos for select to authenticated
  using (owner_id = (select auth.uid()));

create policy review_photos_admin_read
  on public.review_photos for select to authenticated
  using (private.is_admin());

revoke all on table public.review_photos from public, anon, authenticated;
grant select on table public.review_photos to anon, authenticated;

create policy review_image_insert_owner
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'review-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and private.can_use_protected_features()
  );

create policy review_image_select_published_owner_admin
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'review-images'
    and (
      exists (
        select 1
        from public.review_photos photo
        join public.public_reviews public_review
          on public_review.id = photo.review_id
        where photo.storage_path = storage.objects.name
          and not private.is_content_hidden('review', public_review.id)
      )
      or (
        (select auth.uid()) is not null
        and (
          (storage.foldername(storage.objects.name))[1] = (select auth.uid())::text
          or private.is_admin()
        )
      )
    )
  );

-- Owners can remove an upload that failed before its review transaction was
-- committed. Once an object is referenced by public.review_photos, it must not
-- be deleted directly; physical removal is handled asynchronously through the
-- cleanup queue so database integrity and auditability remain intact.
create policy review_image_delete_owner
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'review-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and not exists (
      select 1
      from public.review_photos photo
      where photo.storage_path = storage.objects.name
    )
  );

-- Extend the existing server-owned cleanup queue with the review bucket.
alter table private.storage_cleanup_jobs
  drop constraint if exists storage_cleanup_jobs_bucket_id_check;
alter table private.storage_cleanup_jobs
  add constraint storage_cleanup_jobs_bucket_id_check
  check (bucket_id in ('avatars', 'spot-images', 'restaurant-images', 'review-images'));

create or replace function private.enqueue_storage_cleanup(
  p_owner_id uuid,
  p_bucket_id text,
  p_source_path text,
  p_action text,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, private, auth, storage
as $$
declare
  job_id uuid := gen_random_uuid();
  stored_owner uuid;
  destination text;
  existing_id uuid;
  extension text;
begin
  if p_bucket_id not in (
        'avatars', 'spot-images', 'restaurant-images', 'review-images'
      )
      or p_action not in ('delete', 'rehome')
      or char_length(coalesce(p_source_path, '')) < 3 then
    raise exception using errcode = '22023',
      message = 'Invalid storage cleanup request';
  end if;

  if not exists (
    select 1 from storage.objects object
    where object.bucket_id = p_bucket_id and object.name = p_source_path
  ) then
    return null;
  end if;

  select p_owner_id into stored_owner
  where exists (select 1 from auth.users where id = p_owner_id);

  if p_action = 'rehome' then
    extension := lower(substring(p_source_path from '(\.[A-Za-z0-9]+)$'));
    if extension not in ('.jpg', '.jpeg', '.png', '.webp') then
      raise exception using errcode = '22023',
        message = 'Unsupported retained object type';
    end if;
    destination := 'retained/' || job_id::text || extension;
  end if;

  insert into private.storage_cleanup_jobs (
    id, owner_id, bucket_id, source_path, action, destination_path, stage,
    reason
  ) values (
    job_id, stored_owner, p_bucket_id, p_source_path, p_action, destination,
    case when p_action = 'rehome' then 'rehome_copy' else 'delete_object' end,
    p_reason
  )
  on conflict (bucket_id, source_path)
    where status in ('pending', 'processing', 'failed')
    do nothing
  returning id into existing_id;

  if existing_id is not null then return existing_id; end if;

  select id into existing_id
  from private.storage_cleanup_jobs
  where bucket_id = p_bucket_id
    and source_path = p_source_path
    and status in ('pending', 'processing', 'failed')
  order by created_at desc
  limit 1;
  return existing_id;
end;
$$;

revoke all on function private.enqueue_storage_cleanup(uuid,text,text,text,text)
  from public, anon, authenticated;

-- A client normally removes uploads when the review transaction fails. This
-- server sweep closes the network-loss case by queuing only objects that have
-- remained unreferenced beyond a conservative in-flight grace period.
create or replace function private.enqueue_orphaned_review_uploads(
  p_older_than interval default interval '24 hours'
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
declare
  orphan record;
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
      private.storage_path_owner(orphan.name),
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

revoke all on function private.enqueue_orphaned_review_uploads(interval)
  from public, anon, authenticated;

select cron.schedule(
  'queue-orphaned-review-images',
  '30 3 * * *',
  $$ select private.enqueue_orphaned_review_uploads(interval '24 hours'); $$
);

create or replace function private.queue_removed_review_photo()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
begin
  perform private.enqueue_storage_cleanup(
    old.owner_id,
    'review-images',
    old.storage_path,
    'delete',
    'review_photo_removed'
  );
  return null;
end;
$$;

revoke all on function private.queue_removed_review_photo()
  from public, anon, authenticated;

create trigger review_photo_cleanup_after_delete
after delete on public.review_photos
for each row execute function private.queue_removed_review_photo();

create or replace function private.remove_review_photos_when_unpublished()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if (old.status = 'published' and new.status <> 'published')
      or (old.user_id is not null and new.user_id is null) then
    delete from public.review_photos where review_id = new.id;
  end if;
  return null;
end;
$$;

revoke all on function private.remove_review_photos_when_unpublished()
  from public, anon, authenticated;

create trigger review_photos_remove_when_unpublished
after update of status, user_id on public.reviews
for each row execute function private.remove_review_photos_when_unpublished();

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
declare
  existing public.reviews;
  saved public.reviews;
  author_name text;
  selected_review_id uuid;
  photo_path text;
  prior_paths text[] := '{}';
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
    if photo_path !~ (
          '^' || auth.uid()::text || '/' || selected_review_id::text ||
          '/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'
        )
        or not exists (
          select 1 from storage.objects object
          where object.bucket_id = 'review-images'
            and object.name = photo_path
            and object.owner_id = auth.uid()::text
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
        version = version + 1,
        updated_at = clock_timestamp()
    where id = existing.id
    returning * into saved;
  else
    insert into public.reviews (
      id, user_id, target_type, target_id, rating, body, author_display_name
    ) values (
      selected_review_id, auth.uid(), p_target_type, p_target_id, p_rating,
      btrim(p_body), author_name
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
    version, created_at, updated_at
  ) values (
    saved.id, saved.target_type, saved.target_id, saved.rating, saved.body,
    saved.author_display_name, saved.version, saved.created_at, saved.updated_at
  ) on conflict (id) do update set
    rating = excluded.rating,
    body = excluded.body,
    author_display_name = excluded.author_display_name,
    version = excluded.version,
    updated_at = excluded.updated_at;

  perform private.recalculate_target_rating(p_target_type, p_target_id);
  return (to_jsonb(saved) - 'user_id') || jsonb_build_object(
    'photo_paths', coalesce(p_photo_paths, '{}')
  );
end;
$$;

revoke all on function public.upsert_review_with_photos(
  text,uuid,integer,text,integer,text[],uuid
) from public, anon, authenticated;
grant execute on function public.upsert_review_with_photos(
  text,uuid,integer,text,integer,text[],uuid
) to authenticated;

create or replace function public.admin_list_moderation_cases()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'Admin permission required';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', mc.id,
      'reporter_id', mc.reporter_id,
      'target_type', mc.target_type,
      'target_id', mc.target_id,
      'reason', mc.reason,
      'explanation', mc.explanation,
      'status', mc.status,
      'version', mc.version,
      'created_at', mc.created_at,
      'target_preview', case
        when mc.target_type = 'review' then coalesce(pr.body, '[Review unavailable]')
        when mc.target_type = 'spot' then coalesce(ps.name, '[Spot unavailable]')
        when mc.target_type = 'restaurant' then coalesce(pe.name, '[Restaurant unavailable]')
        when mc.target_type = 'guide' then coalesce(pg.title, '[Guide unavailable]')
        else '[Preview unavailable]'
      end,
      'review_photo_paths', case when mc.target_type = 'review' then coalesce((
        select jsonb_agg(photo.storage_path order by photo.sort_order)
        from public.review_photos photo
        where photo.review_id = mc.target_id
      ), '[]'::jsonb) else '[]'::jsonb end
    ) order by mc.created_at)
    from public.moderation_cases mc
    left join public.public_reviews pr
      on mc.target_type = 'review' and pr.id = mc.target_id
    left join public.published_spots ps
      on mc.target_type = 'spot' and ps.id = mc.target_id
    left join public.published_restaurants pe
      on mc.target_type = 'restaurant' and pe.id = mc.target_id
    left join public.published_guides pg
      on mc.target_type = 'guide' and pg.id = mc.target_id
    where mc.status in ('pending', 'under_review', 'escalated')
  ), '[]'::jsonb);
end;
$$;

commit;
