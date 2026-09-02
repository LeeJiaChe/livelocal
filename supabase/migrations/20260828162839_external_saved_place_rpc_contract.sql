begin;

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
  actor uuid := auth.uid();
  saved public.saved_places;
begin
  if not private.can_use_protected_features() then
    raise exception using errcode = '42501', message = 'Account cannot manage saved places';
  end if;
  if p_target_type <> 'external'
      or p_external_provider <> 'google'
      or char_length(p_target_id) not between 8 and 256
      or p_target_id !~ '^[A-Za-z0-9_-]+$' then
    raise exception using errcode = '22023', message = 'Unsupported external place';
  end if;

  if p_saved then
    insert into public.saved_places (
      user_id, external_provider, external_place_id
    ) values (
      actor, p_external_provider, p_target_id
    ) on conflict do nothing;
  else
    delete from public.saved_places
    where user_id = actor
      and external_provider = p_external_provider
      and external_place_id = p_target_id;
  end if;

  select * into saved
  from public.saved_places
  where user_id = actor
    and external_provider = p_external_provider
    and external_place_id = p_target_id;

  return jsonb_build_object(
    'target_type', p_target_type,
    'target_id', p_target_id,
    'external_provider', p_external_provider,
    'saved', found,
    'saved_at', saved.saved_at
  );
end;
$$;

revoke all on function public.set_saved_place(text, text, boolean, text)
  from public, anon;
grant execute on function public.set_saved_place(text, text, boolean, text)
  to authenticated;

commit;
