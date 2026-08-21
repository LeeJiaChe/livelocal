-- Migration: 202608210003_saved_route_resolution.sql
-- Description: Add RPC fetch_saved_route_candidates to resolve coordinates and metadata directly from published entities for itinerary route generation, independent of discovery pagination caches.

begin;

create or replace function public.fetch_saved_route_candidates(
  p_collection_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  actor uuid := auth.uid();
  result jsonb;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot generate saved routes';
  end if;

  if p_collection_id is not null then
    -- Verify collection belongs to current user
    if not exists (select 1 from public.saved_collections where id = p_collection_id and user_id = actor) then
      raise exception using errcode = 'P0002', message = 'Collection not found';
    end if;

    select coalesce(jsonb_agg(
      jsonb_build_object(
        'saved_place_id', sp.id,
        'target_type', case when sp.spot_id is not null then 'spot' else 'restaurant' end,
        'target_id', coalesce(sp.spot_id, sp.restaurant_id),
        'name', coalesce(ps.name, pr.name),
        'state', coalesce(ps.state, pr.state, ''),
        'city', coalesce(ps.city, pr.city, ''),
        'latitude', coalesce(ps.latitude, pr.latitude),
        'longitude', coalesce(ps.longitude, pr.longitude),
        'category_or_cuisine', coalesce(ps.category, pr.cuisine_type, ''),
        'best_time', ps.best_time,
        'things_to_do', ps.things_to_do,
        'reviewed_dishes', pr.reviewed_dishes,
        'price_range', coalesce(ps.price_range, pr.price_range),
        'image_url', coalesce(ps.image_path, pr.cover_image_path),
        'rating', coalesce(ps.rating_average, pr.rating_average, 0.0),
        'review_count', coalesce(ps.review_count, pr.review_count, 0)
      ) order by sci.added_at desc
    ), '[]'::jsonb)
    into result
    from public.saved_collection_items sci
    join public.saved_places sp on sp.id = sci.saved_place_id and sp.user_id = actor
    left join public.published_spots ps on ps.id = sp.spot_id
    left join public.published_restaurants pr on pr.id = sp.restaurant_id
    where sci.collection_id = p_collection_id
      and (ps.id is not null or pr.id is not null);
  else
    select coalesce(jsonb_agg(
      jsonb_build_object(
        'saved_place_id', sp.id,
        'target_type', case when sp.spot_id is not null then 'spot' else 'restaurant' end,
        'target_id', coalesce(sp.spot_id, sp.restaurant_id),
        'name', coalesce(ps.name, pr.name),
        'state', coalesce(ps.state, pr.state, ''),
        'city', coalesce(ps.city, pr.city, ''),
        'latitude', coalesce(ps.latitude, pr.latitude),
        'longitude', coalesce(ps.longitude, pr.longitude),
        'category_or_cuisine', coalesce(ps.category, pr.cuisine_type, ''),
        'best_time', ps.best_time,
        'things_to_do', ps.things_to_do,
        'reviewed_dishes', pr.reviewed_dishes,
        'price_range', coalesce(ps.price_range, pr.price_range),
        'image_url', coalesce(ps.image_path, pr.cover_image_path),
        'rating', coalesce(ps.rating_average, pr.rating_average, 0.0),
        'review_count', coalesce(ps.review_count, pr.review_count, 0)
      ) order by sp.saved_at desc
    ), '[]'::jsonb)
    into result
    from public.saved_places sp
    left join public.published_spots ps on ps.id = sp.spot_id
    left join public.published_restaurants pr on pr.id = sp.restaurant_id
    where sp.user_id = actor
      and (ps.id is not null or pr.id is not null);
  end if;

  return result;
end;
$$;

revoke all on function public.fetch_saved_route_candidates(uuid) from public;
grant execute on function public.fetch_saved_route_candidates(uuid) to authenticated;

commit;
