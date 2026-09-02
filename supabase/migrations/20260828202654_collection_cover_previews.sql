begin;

-- Collection covers are derived from the same stable membership order used by
-- collection detail (newest added first). Each logical slot is retained even
-- when its item has no image; external provider display data is resolved on
-- demand by the app and is never copied into LiveLocal tables.
create or replace function public.list_my_saved_collections()
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
    raise exception using errcode = '42501', message = 'Account cannot view saved collections';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'user_id', c.user_id,
      'name', c.name,
      'description', c.description,
      'created_at', c.created_at,
      'updated_at', c.updated_at,
      'item_count', coalesce(items_summary.total_items, 0),
      'spot_count', coalesce(items_summary.total_spots, 0),
      'restaurant_count', coalesce(items_summary.total_restaurants, 0),
      'external_count', coalesce(items_summary.total_external, 0),
      'cover_items', coalesce(items_summary.cover_items, '[]'::jsonb),
      -- Legacy single-cover keys remain for older app builds.
      'cover_target_type', items_summary.cover_items #>> '{0,target_type}',
      'cover_image_url', items_summary.cover_items #>> '{0,image_path}',
      'cover_image_path', items_summary.cover_items #>> '{0,image_path}'
    ) order by c.updated_at desc
  ), '[]'::jsonb)
  into result
  from public.saved_collections c
  left join lateral (
    select
      count(sci.id) as total_items,
      count(sp.spot_id) as total_spots,
      count(sp.restaurant_id) as total_restaurants,
      count(sp.external_place_id) as total_external,
      (
        select coalesce(jsonb_agg(
          jsonb_build_object(
            'target_type', preview.target_type,
            'target_id', preview.target_id,
            'external_provider', preview.external_provider,
            'image_path', preview.image_path
          ) order by preview.added_at desc
        ), '[]'::jsonb)
        from (
          select
            sci_preview.added_at,
            case
              when sp_preview.spot_id is not null then 'spot'
              when sp_preview.restaurant_id is not null then 'restaurant'
              else 'external'
            end as target_type,
            coalesce(
              sp_preview.spot_id::text,
              sp_preview.restaurant_id::text,
              sp_preview.external_place_id
            ) as target_id,
            sp_preview.external_provider,
            coalesce(ps.image_path, pr.cover_image_path) as image_path
          from public.saved_collection_items sci_preview
          join public.saved_places sp_preview
            on sp_preview.id = sci_preview.saved_place_id
            and sp_preview.user_id = actor
          left join public.published_spots ps on ps.id = sp_preview.spot_id
          left join public.published_restaurants pr
            on pr.id = sp_preview.restaurant_id
          where sci_preview.collection_id = c.id
          order by sci_preview.added_at desc
          limit 4
        ) preview
      ) as cover_items
    from public.saved_collection_items sci
    join public.saved_places sp
      on sp.id = sci.saved_place_id
      and sp.user_id = actor
    where sci.collection_id = c.id
  ) items_summary on true
  where c.user_id = actor;

  return result;
end;
$$;

revoke all on function public.list_my_saved_collections()
  from public, anon;
grant execute on function public.list_my_saved_collections()
  to authenticated;

commit;
