begin;

-- Add is_anonymous column to reviews and public_reviews
alter table public.reviews
  add column if not exists is_anonymous boolean not null default false;

alter table public.public_reviews
  add column if not exists is_anonymous boolean not null default false;

-- 8-parameter RPC with explicit is_anonymous support
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

-- 7-parameter backward compatibility wrapper
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

revoke all on function public.upsert_review_with_photos(
  text,uuid,integer,text,integer,text[],uuid,boolean
) from public, anon, authenticated;
grant execute on function public.upsert_review_with_photos(
  text,uuid,integer,text,integer,text[],uuid,boolean
) to authenticated;

revoke all on function public.upsert_review_with_photos(
  text,uuid,integer,text,integer,text[],uuid
) from public, anon, authenticated;
grant execute on function public.upsert_review_with_photos(
  text,uuid,integer,text,integer,text[],uuid
) to authenticated;

commit;
