begin;

-- A destination is either a stable Google Places identity or a LiveLocal-owned
-- custom location. Existing rows remain custom until a person explicitly links
-- a revision; no fuzzy migration is performed.
alter table public.spot_revisions
  add column place_provider text,
  add column google_place_id text;
alter table public.published_spots
  add column place_provider text,
  add column google_place_id text;
alter table public.restaurant_revisions
  add column place_provider text,
  add column google_place_id text;
alter table public.published_restaurants
  add column place_provider text,
  add column google_place_id text;

alter table public.spot_revisions
  add constraint spot_revision_place_identity check (
    (place_provider is null and google_place_id is null)
    or (
      place_provider = 'google'
      and char_length(google_place_id) between 8 and 256
      and google_place_id ~ '^[A-Za-z0-9_-]+$'
    )
  );
alter table public.published_spots
  add constraint published_spot_place_identity check (
    (place_provider is null and google_place_id is null)
    or (
      place_provider = 'google'
      and char_length(google_place_id) between 8 and 256
      and google_place_id ~ '^[A-Za-z0-9_-]+$'
    )
  );
alter table public.restaurant_revisions
  add constraint restaurant_revision_place_identity check (
    (place_provider is null and google_place_id is null)
    or (
      place_provider = 'google'
      and char_length(google_place_id) between 8 and 256
      and google_place_id ~ '^[A-Za-z0-9_-]+$'
    )
  );
alter table public.published_restaurants
  add constraint published_restaurant_place_identity check (
    (place_provider is null and google_place_id is null)
    or (
      place_provider = 'google'
      and char_length(google_place_id) between 8 and 256
      and google_place_id ~ '^[A-Za-z0-9_-]+$'
    )
  );

create index spot_revisions_google_place_lookup
  on public.spot_revisions(google_place_id)
  where google_place_id is not null;
create index restaurant_revisions_google_place_lookup
  on public.restaurant_revisions(google_place_id)
  where google_place_id is not null;
create unique index published_spots_one_google_identity
  on public.published_spots(google_place_id)
  where place_provider = 'google' and google_place_id is not null;
create unique index published_restaurants_one_google_identity
  on public.published_restaurants(google_place_id)
  where place_provider = 'google' and google_place_id is not null;

create function public.create_spot_draft_v2(
  p_name text,
  p_category text,
  p_description text,
  p_state text,
  p_city text,
  p_address text,
  p_price_range text,
  p_best_time text,
  p_things_to_do text,
  p_image_path text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_place_provider text default null,
  p_google_place_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  created_spot_id uuid;
  created_revision_id uuid;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot create spot drafts';
  end if;
  if not (
    (p_place_provider is null and p_google_place_id is null)
    or (p_place_provider = 'google'
      and char_length(p_google_place_id) between 8 and 256
      and p_google_place_id ~ '^[A-Za-z0-9_-]+$')
  ) then
    raise exception using errcode = '22023', message = 'Invalid place identity';
  end if;
  if p_image_path is not null
      and p_image_path !~ ('^' || actor::text || '/[A-Za-z0-9_-]+\.(jpg|png|webp)$') then
    raise exception using errcode = '22023', message = 'Invalid spot image path';
  end if;

  insert into public.spots(owner_id) values (actor) returning id into created_spot_id;
  insert into public.spot_revisions (
    spot_id, revision_number, author_id, name, category, description,
    state, city, address, price_range, best_time, things_to_do,
    image_path, latitude, longitude, place_provider, google_place_id
  ) values (
    created_spot_id, 1, actor, btrim(p_name), btrim(p_category),
    btrim(p_description), btrim(p_state), btrim(p_city), btrim(p_address),
    p_price_range, btrim(p_best_time), btrim(p_things_to_do), p_image_path,
    p_latitude, p_longitude, p_place_provider, p_google_place_id
  ) returning id into created_revision_id;
  update public.spots set current_revision_id = created_revision_id
    where id = created_spot_id;

  return jsonb_build_object(
    'spot_id', created_spot_id,
    'revision_id', created_revision_id,
    'image_path', p_image_path,
    'status', 'draft',
    'place_provider', p_place_provider,
    'google_place_id', p_google_place_id,
    'probable_duplicates', private.probable_spot_duplicates(
      p_name, p_address, p_latitude, p_longitude, created_spot_id
    )
  );
end;
$$;

create function public.save_spot_revision_draft_v2(
  p_source_revision_id uuid,
  p_name text,
  p_category text,
  p_description text,
  p_state text,
  p_city text,
  p_address text,
  p_price_range text,
  p_best_time text,
  p_things_to_do text,
  p_image_path text,
  p_latitude double precision,
  p_longitude double precision,
  p_place_provider text default null,
  p_google_place_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
declare
  entity public.spots;
  source public.spot_revisions;
  saved public.spot_revisions;
  next_number integer;
  selected_image_path text;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot revise spots';
  end if;
  if not (
    (p_place_provider is null and p_google_place_id is null)
    or (p_place_provider = 'google'
      and char_length(p_google_place_id) between 8 and 256
      and p_google_place_id ~ '^[A-Za-z0-9_-]+$')
  ) then
    raise exception using errcode = '22023', message = 'Invalid place identity';
  end if;
  select * into entity from public.spots
    where owner_id = auth.uid() and current_revision_id = p_source_revision_id
    for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Current owned spot revision not found';
  end if;
  select * into source from public.spot_revisions where id = p_source_revision_id for update;
  if source.status not in ('draft','submitted','under_review','approved','rejected','withdrawn') then
    raise exception using errcode = '22023', message = 'Spot revision cannot be edited';
  end if;
  selected_image_path := coalesce(p_image_path, source.image_path);
  if selected_image_path is null
      or selected_image_path !~ ('^' || auth.uid()::text || '/[A-Za-z0-9_-]+\.(jpg|png|webp)$')
      or not exists (select 1 from storage.objects object
        where object.bucket_id = 'spot-images' and object.name = selected_image_path) then
    raise exception using errcode = '22023', message = 'An uploaded owned spot image is required';
  end if;

  if source.status = 'draft' then
    update public.spot_revisions set
      name=btrim(p_name), category=btrim(p_category), description=btrim(p_description),
      state=btrim(p_state), city=btrim(p_city), address=btrim(p_address),
      price_range=p_price_range, best_time=btrim(p_best_time),
      things_to_do=btrim(p_things_to_do), image_path=selected_image_path,
      image_rights_confirmed_at=null, latitude=p_latitude, longitude=p_longitude,
      place_provider=p_place_provider, google_place_id=p_google_place_id,
      duplicate_override_reason=null, updated_at=clock_timestamp()
    where id=source.id returning * into saved;
  else
    if source.status in ('submitted','under_review') then
      update public.spot_revisions set status='withdrawn', updated_at=clock_timestamp()
        where id=source.id;
    end if;
    select coalesce(max(revision_number),0)+1 into next_number
      from public.spot_revisions where spot_id=entity.id;
    insert into public.spot_revisions (
      spot_id, revision_number, author_id, name, category, description,
      state, city, address, price_range, best_time, things_to_do, image_path,
      latitude, longitude, place_provider, google_place_id
    ) values (
      entity.id, next_number, auth.uid(), btrim(p_name), btrim(p_category),
      btrim(p_description), btrim(p_state), btrim(p_city), btrim(p_address),
      p_price_range, btrim(p_best_time), btrim(p_things_to_do), selected_image_path,
      p_latitude, p_longitude, p_place_provider, p_google_place_id
    ) returning * into saved;
    update public.spots set current_revision_id=saved.id where id=entity.id;
  end if;
  insert into public.audit_events(actor_id,action,target_type,target_id,metadata)
  values (auth.uid(),'spot.revision_draft_saved','spot',entity.id,
    jsonb_build_object('source_revision_id',source.id,'revision_id',saved.id,
      'revision_number',saved.revision_number,'place_provider',saved.place_provider,
      'google_place_id',saved.google_place_id));
  return jsonb_build_object(
    'spot_id',entity.id,'revision_id',saved.id,'image_path',saved.image_path,
    'status','draft','place_provider',saved.place_provider,
    'google_place_id',saved.google_place_id,
    'probable_duplicates',private.probable_spot_duplicates(
      saved.name,saved.address,saved.latitude,saved.longitude,entity.id));
end;
$$;

create function public.create_restaurant_draft_v2(
  p_name text,
  p_address text,
  p_state text,
  p_city text,
  p_cuisine_type text,
  p_price_range text,
  p_reviewed_dishes text,
  p_social_media_url text,
  p_cover_image_path text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_ai_assisted boolean default false,
  p_ai_source_platform text default null,
  p_place_provider text default null,
  p_google_place_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  created_id uuid;
  revision_id uuid;
begin
  if not private.can_use_protected_features()
      or private.current_role(auth.uid()) <> 'influencer' then
    raise exception using errcode='42501', message='Approved creator role required';
  end if;
  if not private.is_supported_social_url(p_social_media_url,null) then
    raise exception using errcode='22023', message='Unsupported social URL';
  end if;
  if not ((p_place_provider is null and p_google_place_id is null)
    or (p_place_provider='google' and char_length(p_google_place_id) between 8 and 256
      and p_google_place_id ~ '^[A-Za-z0-9_-]+$')) then
    raise exception using errcode='22023', message='Invalid place identity';
  end if;
  if p_cover_image_path is not null and p_cover_image_path !~
      ('^'||auth.uid()::text||'/[A-Za-z0-9_-]+\.(jpg|png|webp)$') then
    raise exception using errcode='22023', message='Invalid restaurant image path';
  end if;
  if coalesce(p_ai_assisted,false) then
    if p_ai_source_platform is null or p_ai_source_platform not in
      ('instagram','tiktok','google_maps','website') then
      raise exception using errcode='22023', message='Valid AI source platform required when AI-assisted';
    end if;
  elsif p_ai_source_platform is not null then
    raise exception using errcode='22023', message='AI source platform must be null when not AI-assisted';
  end if;
  insert into public.restaurants(owner_id) values(auth.uid()) returning id into created_id;
  insert into public.restaurant_revisions(
    restaurant_id,revision_number,author_id,name,address,state,city,cuisine_type,
    price_range,reviewed_dishes,social_media_url,cover_image_path,latitude,longitude,
    ai_assisted,ai_source_platform,place_provider,google_place_id
  ) values (
    created_id,1,auth.uid(),btrim(p_name),btrim(p_address),btrim(p_state),btrim(p_city),
    btrim(p_cuisine_type),p_price_range,btrim(p_reviewed_dishes),btrim(p_social_media_url),
    p_cover_image_path,p_latitude,p_longitude,coalesce(p_ai_assisted,false),
    p_ai_source_platform,p_place_provider,p_google_place_id
  ) returning id into revision_id;
  update public.restaurants set current_revision_id=revision_id where id=created_id;
  return jsonb_build_object(
    'restaurant_id',created_id,'revision_id',revision_id,'image_path',p_cover_image_path,
    'status','draft','place_provider',p_place_provider,'google_place_id',p_google_place_id,
    'probable_duplicates',private.probable_restaurant_duplicates(
      p_name,p_address,p_latitude,p_longitude,created_id));
end;
$$;

create function public.save_restaurant_revision_draft_v2(
  p_source_revision_id uuid,
  p_name text,
  p_address text,
  p_state text,
  p_city text,
  p_cuisine_type text,
  p_price_range text,
  p_reviewed_dishes text,
  p_social_media_url text,
  p_cover_image_path text default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_ai_assisted boolean default false,
  p_ai_source_platform text default null,
  p_place_provider text default null,
  p_google_place_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, storage
as $$
declare
  entity public.restaurants;
  source public.restaurant_revisions;
  saved public.restaurant_revisions;
  next_number integer;
  selected_image_path text;
begin
  if not private.can_use_protected_features()
      or private.current_role(auth.uid()) <> 'influencer' then
    raise exception using errcode='42501', message='Approved creator role required';
  end if;
  if not private.is_supported_social_url(p_social_media_url,null) then
    raise exception using errcode='22023', message='Unsupported social URL';
  end if;
  if not ((p_place_provider is null and p_google_place_id is null)
    or (p_place_provider='google' and char_length(p_google_place_id) between 8 and 256
      and p_google_place_id ~ '^[A-Za-z0-9_-]+$')) then
    raise exception using errcode='22023', message='Invalid place identity';
  end if;
  if coalesce(p_ai_assisted,false) then
    if p_ai_source_platform is null or p_ai_source_platform not in
      ('instagram','tiktok','google_maps','website') then
      raise exception using errcode='22023', message='Valid AI source platform required when AI-assisted';
    end if;
  elsif p_ai_source_platform is not null then
    raise exception using errcode='22023', message='AI source platform must be null when not AI-assisted';
  end if;
  select * into entity from public.restaurants where owner_id=auth.uid()
    and current_revision_id=p_source_revision_id and ownership_status='creator_owned' for update;
  if not found then raise exception using errcode='P0002', message='Current owned restaurant revision not found'; end if;
  select * into source from public.restaurant_revisions where id=p_source_revision_id for update;
  if source.status not in ('draft','submitted','under_review','approved','rejected','withdrawn') then
    raise exception using errcode='22023', message='Restaurant revision cannot be edited';
  end if;
  selected_image_path:=coalesce(p_cover_image_path,source.cover_image_path);
  if selected_image_path is null or selected_image_path !~
      ('^'||auth.uid()::text||'/[A-Za-z0-9_-]+\.(jpg|png|webp)$')
      or not exists(select 1 from storage.objects object
        where object.bucket_id='restaurant-images' and object.name=selected_image_path) then
    raise exception using errcode='22023', message='Valid restaurant image required';
  end if;
  if source.status='draft' then
    update public.restaurant_revisions set
      name=btrim(p_name),address=btrim(p_address),state=btrim(p_state),city=btrim(p_city),
      cuisine_type=btrim(p_cuisine_type),price_range=p_price_range,
      reviewed_dishes=btrim(p_reviewed_dishes),social_media_url=btrim(p_social_media_url),
      cover_image_path=selected_image_path,latitude=p_latitude,longitude=p_longitude,
      ai_assisted=coalesce(p_ai_assisted,false),ai_source_platform=p_ai_source_platform,
      place_provider=p_place_provider,google_place_id=p_google_place_id,
      decision_reason=null,updated_at=clock_timestamp()
    where id=source.id returning * into saved;
  else
    select coalesce(max(revision_number),0)+1 into next_number
      from public.restaurant_revisions where restaurant_id=entity.id;
    insert into public.restaurant_revisions(
      restaurant_id,revision_number,author_id,name,address,state,city,cuisine_type,
      price_range,reviewed_dishes,social_media_url,cover_image_path,latitude,longitude,
      status,ai_assisted,ai_source_platform,place_provider,google_place_id
    ) values (
      entity.id,next_number,auth.uid(),btrim(p_name),btrim(p_address),btrim(p_state),
      btrim(p_city),btrim(p_cuisine_type),p_price_range,btrim(p_reviewed_dishes),
      btrim(p_social_media_url),selected_image_path,p_latitude,p_longitude,'draft',
      coalesce(p_ai_assisted,false),p_ai_source_platform,p_place_provider,p_google_place_id
    ) returning * into saved;
    update public.restaurants set current_revision_id=saved.id where id=entity.id;
  end if;
  insert into public.audit_events(actor_id,action,target_type,target_id,metadata)
  values(auth.uid(),'restaurant.revision_draft_saved','restaurant',entity.id,
    jsonb_build_object('source_revision_id',source.id,'revision_id',saved.id,
      'revision_number',saved.revision_number,'place_provider',saved.place_provider,
      'google_place_id',saved.google_place_id));
  return jsonb_build_object(
    'restaurant_id',entity.id,'revision_id',saved.id,'status',saved.status,
    'revision_number',saved.revision_number,'place_provider',saved.place_provider,
    'google_place_id',saved.google_place_id);
end;
$$;

revoke all on function public.create_spot_draft_v2(text,text,text,text,text,text,text,text,text,text,double precision,double precision,text,text) from public,anon;
revoke all on function public.save_spot_revision_draft_v2(uuid,text,text,text,text,text,text,text,text,text,text,double precision,double precision,text,text) from public,anon;
revoke all on function public.create_restaurant_draft_v2(text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text,text,text) from public,anon;
revoke all on function public.save_restaurant_revision_draft_v2(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text,text,text) from public,anon;
grant execute on function public.create_spot_draft_v2(text,text,text,text,text,text,text,text,text,text,double precision,double precision,text,text) to authenticated;
grant execute on function public.save_spot_revision_draft_v2(uuid,text,text,text,text,text,text,text,text,text,text,double precision,double precision,text,text) to authenticated;
grant execute on function public.create_restaurant_draft_v2(text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text,text,text) to authenticated;
grant execute on function public.save_restaurant_revision_draft_v2(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text,text,text) to authenticated;

-- Publication identity is always derived from the approved revision. This
-- keeps both existing moderation RPCs and older clients compatible.
create function private.sync_published_spot_place_identity()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  select revision.place_provider, revision.google_place_id
    into new.place_provider, new.google_place_id
  from public.spot_revisions revision where revision.id = new.revision_id;
  return new;
end;
$$;
create trigger published_spot_place_identity_sync
before insert or update of revision_id on public.published_spots
for each row execute function private.sync_published_spot_place_identity();

create function private.sync_published_restaurant_place_identity()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  select revision.place_provider, revision.google_place_id
    into new.place_provider, new.google_place_id
  from public.restaurant_revisions revision where revision.id = new.revision_id;
  return new;
end;
$$;
create trigger published_restaurant_place_identity_sync
before insert or update of revision_id on public.published_restaurants
for each row execute function private.sync_published_restaurant_place_identity();
revoke all on function private.sync_published_spot_place_identity() from public;
revoke all on function private.sync_published_restaurant_place_identity() from public;

drop function public.list_my_spot_submissions();
create function public.list_my_spot_submissions()
returns table (
  spot_id uuid, revision_id uuid, moderation_version integer,
  status public.content_revision_status, name text, category text,
  description text, state text, city text, address text, price_range text,
  best_time text, things_to_do text, image_path text,
  latitude double precision, longitude double precision,
  place_provider text, google_place_id text, decision_reason text,
  has_approved_revision boolean, updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if not private.can_use_protected_features() then
    raise exception using errcode='42501', message='Account cannot manage spot submissions';
  end if;
  return query
  select entity.id,revision.id,entity.moderation_version,revision.status,
    revision.name,revision.category,revision.description,revision.state,
    revision.city,revision.address,revision.price_range,revision.best_time,
    revision.things_to_do,revision.image_path,revision.latitude,revision.longitude,
    revision.place_provider,revision.google_place_id,decision.reason,
    entity.approved_revision_id is not null,revision.updated_at
  from public.spots entity
  join public.spot_revisions revision on revision.id=entity.current_revision_id
  left join lateral (
    select moderation.reason from public.spot_moderation_decisions moderation
    where moderation.revision_id=revision.id
    order by moderation.created_at desc limit 1
  ) decision on true
  where entity.owner_id=auth.uid()
  order by revision.updated_at desc,entity.id;
end;
$$;

drop function public.list_my_restaurant_submissions();
create function public.list_my_restaurant_submissions()
returns table (
  restaurant_id uuid, revision_id uuid, moderation_version integer,
  status public.content_revision_status, name text, address text, state text,
  city text, cuisine_type text, price_range text, reviewed_dishes text,
  social_media_url text, cover_image_path text, latitude double precision,
  longitude double precision, place_provider text, google_place_id text,
  decision_reason text, has_approved_revision boolean, updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if not private.can_use_protected_features()
      or private.current_role(auth.uid()) <> 'influencer' then
    raise exception using errcode='42501', message='Approved creator role required';
  end if;
  return query
  select entity.id,revision.id,entity.moderation_version,revision.status,
    revision.name,revision.address,revision.state,revision.city,
    revision.cuisine_type,revision.price_range,revision.reviewed_dishes,
    revision.social_media_url,revision.cover_image_path,revision.latitude,
    revision.longitude,revision.place_provider,revision.google_place_id,
    decision.reason,entity.approved_revision_id is not null,revision.updated_at
  from public.restaurants entity
  join public.restaurant_revisions revision on revision.id=entity.current_revision_id
  left join lateral (
    select moderation.reason from public.restaurant_moderation_decisions moderation
    where moderation.revision_id=revision.id
    order by moderation.created_at desc limit 1
  ) decision on true
  where entity.owner_id=auth.uid()
  order by revision.updated_at desc,entity.id;
end;
$$;
revoke all on function public.list_my_spot_submissions() from public,anon;
revoke all on function public.list_my_restaurant_submissions() from public,anon;
grant execute on function public.list_my_spot_submissions() to authenticated;
grant execute on function public.list_my_restaurant_submissions() to authenticated;

-- One call enriches a complete Google search page. Only publication tables are
-- consulted, so draft and moderation data cannot leak.
create function public.lookup_place_enrichments(p_google_place_ids text[])
returns jsonb
language plpgsql
stable
security invoker
set search_path = pg_catalog, public
as $$
declare
  normalized_ids text[];
  result jsonb;
begin
  if p_google_place_ids is null or cardinality(p_google_place_ids) < 1
      or cardinality(p_google_place_ids) > 20 then
    raise exception using errcode='22023', message='Provide between 1 and 20 Google Place IDs';
  end if;
  select array_agg(distinct value) into normalized_ids
  from unnest(p_google_place_ids) value
  where char_length(value) between 8 and 256 and value ~ '^[A-Za-z0-9_-]+$';
  if normalized_ids is null then
    raise exception using errcode='22023', message='Invalid Google Place IDs';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'google_place_id',identity.google_place_id,
    'spot',case when spot.id is null then null else jsonb_build_object(
      'id',spot.id,'name',spot.name,'category',spot.category,
      'description',spot.description,'best_time',spot.best_time,
      'things_to_do',spot.things_to_do,'image_path',spot.image_path,
      'rating',spot.rating_average,'review_count',spot.review_count,
      'upvote_count',spot.upvote_count) end,
    'eat',case when eat.id is null then null else jsonb_build_object(
      'id',eat.id,'name',eat.name,'cuisine_type',eat.cuisine_type,
      'reviewed_dishes',eat.reviewed_dishes,'price_range',eat.price_range,
      'creator_display_name',eat.creator_display_name,
      'cover_image_path',eat.cover_image_path,'rating',eat.rating_average,
      'review_count',eat.review_count) end
  ) order by identity.google_place_id),'[]'::jsonb) into result
  from unnest(normalized_ids) identity(google_place_id)
  left join public.published_spots spot
    on spot.place_provider='google' and spot.google_place_id=identity.google_place_id
  left join public.published_restaurants eat
    on eat.place_provider='google' and eat.google_place_id=identity.google_place_id
  where spot.id is not null or eat.id is not null;
  return result;
end;
$$;
revoke all on function public.lookup_place_enrichments(text[]) from public;
grant execute on function public.lookup_place_enrichments(text[]) to anon,authenticated;

create function private.resolve_destination_identity(
  p_target_type text,
  p_target_id text,
  p_external_provider text default null
)
returns table(
  canonical_type text,
  canonical_id text,
  canonical_provider text,
  internal_id uuid
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare parsed_id uuid;
begin
  if p_target_type in ('spot','restaurant') then
    begin parsed_id:=p_target_id::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='22023', message='Invalid saved-place target';
    end;
    if p_external_provider is not null then
      raise exception using errcode='22023', message='Invalid external provider';
    end if;
    if p_target_type='spot' then
      return query
      select case when place.google_place_id is null then 'spot' else 'external' end,
        coalesce(place.google_place_id,place.id::text),
        case when place.google_place_id is null then null else 'google' end,
        place.id
      from public.published_spots place where place.id=parsed_id;
    else
      return query
      select case when place.google_place_id is null then 'restaurant' else 'external' end,
        coalesce(place.google_place_id,place.id::text),
        case when place.google_place_id is null then null else 'google' end,
        place.id
      from public.published_restaurants place where place.id=parsed_id;
    end if;
    if not found then raise exception using errcode='P0002', message='Place is unavailable'; end if;
  elsif p_target_type='external' and p_external_provider='google'
      and char_length(p_target_id) between 8 and 256
      and p_target_id ~ '^[A-Za-z0-9_-]+$' then
    return query select 'external'::text,p_target_id,'google'::text,null::uuid;
  else
    raise exception using errcode='22023', message='Unsupported saved-place target';
  end if;
end;
$$;
revoke all on function private.resolve_destination_identity(text,text,text) from public;

create or replace function public.set_place_collections(
  p_target_type text,
  p_target_id text,
  p_collection_ids uuid[],
  p_external_provider text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid:=auth.uid();
  identity record;
  canonical_place_id uuid;
  legacy_place_id uuid;
  cid uuid;
  valid_collection_count integer:=0;
  total_memberships integer:=0;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode='42501', message='Account cannot manage saved collections';
  end if;
  select * into identity from private.resolve_destination_identity(
    p_target_type,p_target_id,p_external_provider);
  if p_collection_ids is not null and cardinality(p_collection_ids)>0 then
    select count(*) into valid_collection_count from public.saved_collections
      where user_id=actor and id=any(p_collection_ids);
    if valid_collection_count<>cardinality(p_collection_ids) then
      raise exception using errcode='42501', message='One or more invalid or unauthorized collections';
    end if;
  end if;

  select id into canonical_place_id from public.saved_places where user_id=actor and (
    (identity.canonical_type='spot' and spot_id=identity.internal_id)
    or (identity.canonical_type='restaurant' and restaurant_id=identity.internal_id)
    or (identity.canonical_type='external' and external_provider=identity.canonical_provider
      and external_place_id=identity.canonical_id));

  -- If this published insight now resolves to Google, merge an older local save
  -- into the provider identity. The match is exact and auditable, never fuzzy.
  if identity.canonical_type='external' then
    if p_target_type in ('spot','restaurant') then
      select id into legacy_place_id from public.saved_places where user_id=actor and (
        (p_target_type='spot' and spot_id=identity.internal_id)
        or (p_target_type='restaurant' and restaurant_id=identity.internal_id));
    else
      select saved.id into legacy_place_id
      from public.saved_places saved
      left join public.published_spots spot on spot.id=saved.spot_id
      left join public.published_restaurants eat on eat.id=saved.restaurant_id
      where saved.user_id=actor and coalesce(spot.google_place_id,eat.google_place_id)=identity.canonical_id
      order by saved.saved_at limit 1;
    end if;
    if canonical_place_id is null and legacy_place_id is not null then
      update public.saved_places set spot_id=null,restaurant_id=null,
        external_provider='google',external_place_id=identity.canonical_id
      where id=legacy_place_id returning id into canonical_place_id;
      legacy_place_id:=null;
    elsif canonical_place_id is not null and legacy_place_id is not null
        and canonical_place_id<>legacy_place_id then
      insert into public.saved_collection_items(collection_id,saved_place_id,added_at)
      select collection_id,canonical_place_id,added_at
      from public.saved_collection_items where saved_place_id=legacy_place_id
      on conflict(collection_id,saved_place_id) do nothing;
      delete from public.saved_places where id=legacy_place_id and user_id=actor;
      legacy_place_id:=null;
    end if;
    -- A user may historically have saved both the Spot and Eat rows. Once the
    -- stable Google identity is known, fold every exact linked save into the
    -- canonical destination without any name/address matching.
    if canonical_place_id is not null then
      for legacy_place_id in
        select legacy.id
        from public.saved_places legacy
        left join public.published_spots spot on spot.id=legacy.spot_id
        left join public.published_restaurants eat on eat.id=legacy.restaurant_id
        where legacy.user_id=actor and legacy.id<>canonical_place_id
          and coalesce(spot.google_place_id,eat.google_place_id)=identity.canonical_id
      loop
        insert into public.saved_collection_items(collection_id,saved_place_id,added_at)
        select collection_id,canonical_place_id,added_at
        from public.saved_collection_items where saved_place_id=legacy_place_id
        on conflict(collection_id,saved_place_id) do nothing;
        delete from public.saved_places where id=legacy_place_id and user_id=actor;
      end loop;
    end if;
  end if;

  if p_collection_ids is null or cardinality(p_collection_ids)=0 then
    if canonical_place_id is not null then
      delete from public.saved_collection_items where saved_place_id=canonical_place_id;
      delete from public.saved_places where id=canonical_place_id and user_id=actor;
    end if;
    return jsonb_build_object('target_type',identity.canonical_type,
      'target_id',identity.canonical_id,'external_provider',identity.canonical_provider,
      'saved',false,'collection_ids','[]'::jsonb);
  end if;

  if canonical_place_id is null then
    insert into public.saved_places(user_id,spot_id,restaurant_id,external_provider,external_place_id)
    values(actor,
      case when identity.canonical_type='spot' then identity.internal_id end,
      case when identity.canonical_type='restaurant' then identity.internal_id end,
      identity.canonical_provider,
      case when identity.canonical_type='external' then identity.canonical_id end)
    returning id into canonical_place_id;
  end if;
  delete from public.saved_collection_items item
    using public.saved_collections collection
    where item.saved_place_id=canonical_place_id
      and collection.id=item.collection_id and collection.user_id=actor
      and item.collection_id<>all(p_collection_ids);
  foreach cid in array p_collection_ids loop
    insert into public.saved_collection_items(collection_id,saved_place_id)
    values(cid,canonical_place_id) on conflict do nothing;
  end loop;
  select count(*) into total_memberships from public.saved_collection_items
    where saved_place_id=canonical_place_id;
  update public.saved_collections set updated_at=clock_timestamp()
    where id=any(p_collection_ids) and user_id=actor;
  return jsonb_build_object('target_type',identity.canonical_type,
    'target_id',identity.canonical_id,'external_provider',identity.canonical_provider,
    'saved',total_memberships>0,'collection_ids',to_jsonb(p_collection_ids));
end;
$$;

create or replace function public.list_place_collection_ids(
  p_target_type text,
  p_target_id text,
  p_external_provider text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare actor uuid:=auth.uid(); identity record; result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode='42501', message='Account cannot view saved collections';
  end if;
  select * into identity from private.resolve_destination_identity(
    p_target_type,p_target_id,p_external_provider);
  select coalesce(jsonb_agg(distinct item.collection_id),'[]'::jsonb) into result
  from public.saved_collection_items item
  join public.saved_collections collection on collection.id=item.collection_id and collection.user_id=actor
  join public.saved_places saved on saved.id=item.saved_place_id and saved.user_id=actor
  left join public.published_spots spot on spot.id=saved.spot_id
  left join public.published_restaurants eat on eat.id=saved.restaurant_id
  where (identity.canonical_type='spot' and saved.spot_id=identity.internal_id)
    or (identity.canonical_type='restaurant' and saved.restaurant_id=identity.internal_id)
    or (identity.canonical_type='external' and (
      (saved.external_provider=identity.canonical_provider and saved.external_place_id=identity.canonical_id)
      or spot.google_place_id=identity.canonical_id or eat.google_place_id=identity.canonical_id));
  return result;
end;
$$;

create or replace function public.set_saved_place(
  p_target_type text,
  p_target_id text,
  p_saved boolean,
  p_external_provider text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid:=auth.uid();
  identity record;
  saved public.saved_places;
  canonical_place_id uuid;
  legacy_place_id uuid;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode='42501', message='Account cannot manage saved places';
  end if;
  select * into identity from private.resolve_destination_identity(
    p_target_type,p_target_id,p_external_provider);
  if p_saved then
    select id into canonical_place_id from public.saved_places where user_id=actor and (
      (identity.canonical_type='spot' and spot_id=identity.internal_id)
      or (identity.canonical_type='restaurant' and restaurant_id=identity.internal_id)
      or (identity.canonical_type='external' and external_provider=identity.canonical_provider
        and external_place_id=identity.canonical_id));
    if canonical_place_id is null then
      insert into public.saved_places(user_id,spot_id,restaurant_id,external_provider,external_place_id)
      values(actor,
        case when identity.canonical_type='spot' then identity.internal_id end,
        case when identity.canonical_type='restaurant' then identity.internal_id end,
        identity.canonical_provider,
        case when identity.canonical_type='external' then identity.canonical_id end)
      returning id into canonical_place_id;
    end if;
    -- Exact stable-ID normalization also covers the direct save toggle. Move
    -- any former Spot/Eat memberships before deleting the duplicate save.
    if identity.canonical_type='external' then
      for legacy_place_id in
        select legacy.id
        from public.saved_places legacy
        left join public.published_spots spot on spot.id=legacy.spot_id
        left join public.published_restaurants eat on eat.id=legacy.restaurant_id
        where legacy.user_id=actor and legacy.id<>canonical_place_id
          and coalesce(spot.google_place_id,eat.google_place_id)=identity.canonical_id
      loop
        insert into public.saved_collection_items(collection_id,saved_place_id,added_at)
        select collection_id,canonical_place_id,added_at
        from public.saved_collection_items where saved_place_id=legacy_place_id
        on conflict(collection_id,saved_place_id) do nothing;
        delete from public.saved_places where id=legacy_place_id and user_id=actor;
      end loop;
    end if;
  else
    delete from public.saved_places where user_id=actor and (
      (identity.canonical_type='spot' and spot_id=identity.internal_id)
      or (identity.canonical_type='restaurant' and restaurant_id=identity.internal_id)
      or (identity.canonical_type='external' and external_provider=identity.canonical_provider
        and external_place_id=identity.canonical_id)
      or (identity.canonical_type='external' and (
        spot_id in (select id from public.published_spots where google_place_id=identity.canonical_id)
        or restaurant_id in (select id from public.published_restaurants where google_place_id=identity.canonical_id))));
  end if;
  select * into saved from public.saved_places where user_id=actor and (
    (identity.canonical_type='spot' and spot_id=identity.internal_id)
    or (identity.canonical_type='restaurant' and restaurant_id=identity.internal_id)
    or (identity.canonical_type='external' and external_provider=identity.canonical_provider
      and external_place_id=identity.canonical_id));
  return jsonb_build_object('target_type',identity.canonical_type,
    'target_id',identity.canonical_id,'external_provider',identity.canonical_provider,
    'saved',found,'saved_at',saved.saved_at);
end;
$$;
revoke all on function public.set_place_collections(text,text,uuid[],text) from public,anon;
revoke all on function public.list_place_collection_ids(text,text,text) from public,anon;
revoke all on function public.set_saved_place(text,text,boolean,text) from public,anon;
grant execute on function public.set_place_collections(text,text,uuid[],text) to authenticated;
grant execute on function public.list_place_collection_ids(text,text,text) to authenticated;
grant execute on function public.set_saved_place(text,text,boolean,text) to authenticated;

create or replace function public.fetch_collection_places(p_collection_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare actor uuid:=auth.uid(); result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode='42501', message='Account cannot view collection places';
  end if;
  if not exists(select 1 from public.saved_collections
    where id=p_collection_id and user_id=actor) then
    raise exception using errcode='P0002', message='Collection not found';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'saved_place_id',saved.id,
    'target_type',case when saved.spot_id is not null then 'spot'
      when saved.restaurant_id is not null then 'restaurant' else 'external' end,
    'target_id',coalesce(saved.spot_id::text,saved.restaurant_id::text,saved.external_place_id),
    'external_provider',saved.external_provider,
    'name',coalesce(local_spot.name,linked_spot.name,local_eat.name,linked_eat.name),
    'address',coalesce(local_spot.address,linked_spot.address,local_eat.address,linked_eat.address),
    'state',coalesce(local_spot.state,linked_spot.state,local_eat.state,linked_eat.state),
    'city',coalesce(local_spot.city,linked_spot.city,local_eat.city,linked_eat.city),
    'category_or_cuisine',coalesce(local_spot.category,linked_spot.category,
      local_eat.cuisine_type,linked_eat.cuisine_type),
    'price_range',coalesce(local_spot.price_range,linked_spot.price_range,
      local_eat.price_range,linked_eat.price_range),
    'image_url',coalesce(local_spot.image_path,linked_spot.image_path,
      local_eat.cover_image_path,linked_eat.cover_image_path),
    'rating',coalesce(local_spot.rating_average,linked_spot.rating_average,
      local_eat.rating_average,linked_eat.rating_average),
    'review_count',coalesce(local_spot.review_count,linked_spot.review_count,
      local_eat.review_count,linked_eat.review_count),
    'spot_id',coalesce(local_spot.id,linked_spot.id),
    'restaurant_id',coalesce(local_eat.id,linked_eat.id),
    'best_time',coalesce(local_spot.best_time,linked_spot.best_time),
    'things_to_do',coalesce(local_spot.things_to_do,linked_spot.things_to_do),
    'reviewed_dishes',coalesce(local_eat.reviewed_dishes,linked_eat.reviewed_dishes),
    'added_at',item.added_at
  ) order by item.added_at desc),'[]'::jsonb) into result
  from public.saved_collection_items item
  join public.saved_places saved on saved.id=item.saved_place_id and saved.user_id=actor
  left join public.published_spots local_spot on local_spot.id=saved.spot_id
  left join public.published_restaurants local_eat on local_eat.id=saved.restaurant_id
  left join public.published_spots linked_spot on saved.external_provider='google'
    and linked_spot.place_provider='google' and linked_spot.google_place_id=saved.external_place_id
  left join public.published_restaurants linked_eat on saved.external_provider='google'
    and linked_eat.place_provider='google' and linked_eat.google_place_id=saved.external_place_id
  where item.collection_id=p_collection_id;
  return result;
end;
$$;

create or replace function public.fetch_saved_route_candidates(p_collection_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare actor uuid:=auth.uid(); result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode='42501', message='Account cannot generate saved routes';
  end if;
  if p_collection_id is not null and not exists(select 1 from public.saved_collections
    where id=p_collection_id and user_id=actor) then
    raise exception using errcode='P0002', message='Collection not found';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'saved_place_id',saved.id,
    'target_type',case when saved.spot_id is not null then 'spot'
      when saved.restaurant_id is not null then 'restaurant' else 'external' end,
    'target_id',coalesce(saved.spot_id::text,saved.restaurant_id::text,saved.external_place_id),
    'external_provider',saved.external_provider,
    'name',coalesce(local_spot.name,linked_spot.name,local_eat.name,linked_eat.name),
    'address',coalesce(local_spot.address,linked_spot.address,local_eat.address,linked_eat.address),
    'state',coalesce(local_spot.state,linked_spot.state,local_eat.state,linked_eat.state,''),
    'city',coalesce(local_spot.city,linked_spot.city,local_eat.city,linked_eat.city,''),
    'latitude',coalesce(local_spot.latitude,linked_spot.latitude,local_eat.latitude,linked_eat.latitude),
    'longitude',coalesce(local_spot.longitude,linked_spot.longitude,local_eat.longitude,linked_eat.longitude),
    'category_or_cuisine',coalesce(local_spot.category,linked_spot.category,
      local_eat.cuisine_type,linked_eat.cuisine_type,''),
    'best_time',coalesce(local_spot.best_time,linked_spot.best_time),
    'things_to_do',coalesce(local_spot.things_to_do,linked_spot.things_to_do),
    'reviewed_dishes',coalesce(local_eat.reviewed_dishes,linked_eat.reviewed_dishes),
    'price_range',coalesce(local_spot.price_range,linked_spot.price_range,
      local_eat.price_range,linked_eat.price_range),
    'image_url',coalesce(local_spot.image_path,linked_spot.image_path,
      local_eat.cover_image_path,linked_eat.cover_image_path),
    'rating',coalesce(local_spot.rating_average,linked_spot.rating_average,
      local_eat.rating_average,linked_eat.rating_average,0),
    'review_count',coalesce(local_spot.review_count,linked_spot.review_count,
      local_eat.review_count,linked_eat.review_count,0),
    'spot_id',coalesce(local_spot.id,linked_spot.id),
    'restaurant_id',coalesce(local_eat.id,linked_eat.id)
  ) order by coalesce(membership.added_at,saved.saved_at) desc),'[]'::jsonb) into result
  from public.saved_places saved
  left join lateral (
    select max(item.added_at) added_at from public.saved_collection_items item
    where item.saved_place_id=saved.id and item.collection_id=p_collection_id
  ) membership on p_collection_id is not null
  left join public.published_spots local_spot on local_spot.id=saved.spot_id
  left join public.published_restaurants local_eat on local_eat.id=saved.restaurant_id
  left join public.published_spots linked_spot on saved.external_provider='google'
    and linked_spot.place_provider='google' and linked_spot.google_place_id=saved.external_place_id
  left join public.published_restaurants linked_eat on saved.external_provider='google'
    and linked_eat.place_provider='google' and linked_eat.google_place_id=saved.external_place_id
  where saved.user_id=actor and (p_collection_id is null or membership.added_at is not null)
    and (local_spot.id is not null or local_eat.id is not null
      or saved.external_place_id is not null);
  return result;
end;
$$;
revoke all on function public.fetch_collection_places(uuid) from public,anon;
revoke all on function public.fetch_saved_route_candidates(uuid) from public,anon;
grant execute on function public.fetch_collection_places(uuid) to authenticated;
grant execute on function public.fetch_saved_route_candidates(uuid) to authenticated;

-- Structured guides gain a provider-backed stop mode without invalidating
-- existing listing and custom stop JSON.
create or replace function private.assert_valid_guide_stop_details(p_stop_details jsonb)
returns void
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare item jsonb; listing_id uuid;
begin
  if jsonb_typeof(p_stop_details)<>'array'
      or jsonb_array_length(p_stop_details) not between 2 and 30 then
    raise exception using errcode='22023', message='INVALID_GUIDE_STOP_DETAILS';
  end if;
  for item in select value from jsonb_array_elements(p_stop_details) loop
    if jsonb_typeof(item)<>'object' or item->>'kind' not in ('listing','provider','custom')
        or char_length(btrim(coalesce(item->>'name',''))) not between 2 and 300
        or char_length(btrim(coalesce(item->>'instruction',''))) not between 3 and 500 then
      raise exception using errcode='22023', message='INVALID_GUIDE_STOP_DETAILS';
    end if;
    if item->>'kind'='listing' then
      if item->>'listing_type' not in ('spot','restaurant')
          or coalesce(item->>'listing_id','') !~
            '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$' then
        raise exception using errcode='22023', message='INVALID_GUIDE_LISTING_STOP';
      end if;
      listing_id:=(item->>'listing_id')::uuid;
      if (item->>'listing_type'='spot' and not exists(select 1 from public.published_spots where id=listing_id))
          or (item->>'listing_type'='restaurant' and not exists(select 1 from public.published_restaurants where id=listing_id)) then
        raise exception using errcode='23503', message='GUIDE_LISTING_STOP_UNAVAILABLE';
      end if;
    elsif item->>'kind'='provider' then
      if item->>'place_provider'<>'google'
          or char_length(coalesce(item->>'google_place_id','')) not between 8 and 256
          or (item->>'google_place_id') !~ '^[A-Za-z0-9_-]+$'
          or item ? 'listing_id' or item ? 'listing_type' then
        raise exception using errcode='22023', message='INVALID_GUIDE_PROVIDER_STOP';
      end if;
    elsif item ? 'listing_id' or item ? 'listing_type'
        or item ? 'place_provider' or item ? 'google_place_id' then
      raise exception using errcode='22023', message='INVALID_CUSTOM_GUIDE_STOP';
    end if;
  end loop;
end;
$$;
revoke all on function private.assert_valid_guide_stop_details(jsonb) from public;

commit;
