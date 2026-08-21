begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

select ok(
  private.is_supported_review_post_url(
    'https://www.tiktok.com/@creator/video/123456789'
  ),
  'TikTok video URL is a valid final review source'
);
select ok(
  private.is_supported_review_post_url('https://vm.tiktok.com/ZM123/'),
  'TikTok short URL is a valid final review source'
);
select ok(
  private.is_supported_review_post_url('https://instagram.com/p/ABC123/'),
  'Instagram post URL is a valid final review source'
);
select ok(
  private.is_supported_review_post_url('https://instagram.com/reel/ABC123/'),
  'Instagram Reel URL is a valid final review source'
);
select not_ok(
  private.is_supported_review_post_url('https://tiktok.com/@creator/'),
  'TikTok profile URL cannot be a final review source'
);
select not_ok(
  private.is_supported_review_post_url('https://instagram.com/creator/'),
  'Instagram profile URL cannot be a final review source'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.social_account_connections'::regclass),
  'social connections have RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.social_oauth_states'::regclass),
  'OAuth state has RLS enabled'
);
select not_ok(
  has_table_privilege('authenticated', 'public.social_account_connections', 'select'),
  'authenticated clients cannot read provider tokens'
);
select not_ok(
  has_table_privilege('authenticated', 'public.social_account_connections', 'insert'),
  'authenticated clients cannot insert provider tokens'
);
select not_ok(
  has_table_privilege('authenticated', 'public.social_oauth_states', 'select'),
  'authenticated clients cannot read OAuth state'
);
select not_ok(
  has_table_privilege('authenticated', 'public.social_oauth_states', 'insert'),
  'authenticated clients cannot create OAuth state directly'
);

select * from finish();
rollback;
