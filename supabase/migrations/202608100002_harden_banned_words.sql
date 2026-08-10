create or replace function private.assert_no_banned_words(p_text text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  banned_json jsonb;
  banned text[];
  word text;
  normalized_text text;
begin
  if p_text is null or trim(p_text) = '' then
    return;
  end if;

  select value into banned_json 
  from public.app_settings 
  where key = 'banned_words';

  if banned_json is null or jsonb_typeof(banned_json) <> 'array' then
    raise exception using errcode = 'P0001', message = 'UGC_FILTER_CONFIG_INVALID';
  end if;

  if exists (
    select 1 from jsonb_array_elements(banned_json) x
    where jsonb_typeof(x) <> 'string' or btrim(x#>>'{}') = ''
  ) then
    raise exception using errcode = 'P0001', message = 'UGC_FILTER_CONFIG_INVALID';
  end if;

  if jsonb_array_length(banned_json) = 0 then
    return;
  end if;

  -- Convert JSONB array to text[]
  select array_agg(x) into banned from jsonb_array_elements_text(banned_json) x;
  
  -- Replace all punctuation with space (preserving letters of any language)
  -- then compress repeated whitespaces
  normalized_text := regexp_replace(
    regexp_replace(lower(p_text), '[[:punct:]]+', ' ', 'g'),
    '\s+', ' ', 'g'
  );

  foreach word in array banned
  loop
    -- match whole words using \y
    if normalized_text ~* ('\y' || regexp_replace(word, '([.*+?^${}()|\[\]\\])', '\\\1', 'g') || '\y') then
      raise exception using 
        errcode = '22023', 
        message = 'UGC_CONTENT_RESTRICTED';
    end if;
  end loop;
end;
$$;
