begin;

create or replace function private.is_supported_review_post_url(p_url text)
returns boolean
language sql
immutable
set search_path = pg_catalog
as $$
  select
    p_url ~* '^https://(www[.])?instagram[.]com/(p|reel|reels|tv)/[^/?#]+/?([?#].*)?$'
    or p_url ~* '^https://(www[.])?tiktok[.]com/@[^/?#]+/video/[^/?#]+/?([?#].*)?$'
    or p_url ~* '^https://(vm|vt)[.]tiktok[.]com/[^/?#]+/?([?#].*)?$';
$$;

revoke all on function private.is_supported_review_post_url(text)
  from public, anon, authenticated, service_role;

alter table public.restaurant_revisions
  drop constraint restaurant_social_url_supported;
alter table public.restaurant_revisions
  add constraint restaurant_social_url_review_post check (
    private.is_supported_review_post_url(social_media_url)
  ) not valid;

-- OAuth credentials are server-owned. Mobile roles receive no table grants;
-- Edge Functions use the service role after independently authenticating the
-- caller and checking their current database role.
create table public.social_account_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('tiktok', 'instagram')),
  external_account_id text not null,
  profile_url text not null,
  access_token_ciphertext text not null,
  access_token_iv text not null,
  refresh_token_ciphertext text,
  refresh_token_iv text,
  scopes text[] not null default '{}',
  token_expires_at timestamptz,
  refresh_expires_at timestamptz,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  unique (user_id, platform)
);

create table public.social_oauth_states (
  state_hash text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('tiktok', 'instagram')),
  app_redirect_uri text not null
    check (
      app_redirect_uri ~ '^io[.]livelocal[.]app://'
      or app_redirect_uri ~ '^https://'
    ),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default clock_timestamp()
);

create index social_oauth_states_expiry_idx
  on public.social_oauth_states(expires_at)
  where used_at is null;

alter table public.social_account_connections enable row level security;
alter table public.social_oauth_states enable row level security;

revoke all on table public.social_account_connections
  from public, anon, authenticated;
revoke all on table public.social_oauth_states
  from public, anon, authenticated;
grant all on table public.social_account_connections to service_role;
grant all on table public.social_oauth_states to service_role;

commit;
