begin;

select plan(27);

select ok(
  not has_function_privilege(
    'anon',
    'public.admin_moderate_guide_revision(uuid,text,text,integer)',
    'EXECUTE'
  ),
  'anon cannot moderate Guide revisions'
);
select ok(not has_function_privilege('anon', 'public.create_saved_collection(text,text)', 'EXECUTE'), 'anon cannot create collections');
select ok(not has_function_privilege('anon', 'public.delete_saved_collection(uuid)', 'EXECUTE'), 'anon cannot delete collections');
select ok(not has_function_privilege('anon', 'public.fetch_collection_places(uuid)', 'EXECUTE'), 'anon cannot read private collection places');
select ok(not has_function_privilege('anon', 'public.fetch_saved_route_candidates(uuid)', 'EXECUTE'), 'anon cannot read private route candidates');
select ok(not has_function_privilege('anon', 'public.list_my_guide_submissions()', 'EXECUTE'), 'anon cannot list private Guide submissions');
select ok(not has_function_privilege('anon', 'public.list_my_saved_collections()', 'EXECUTE'), 'anon cannot list private collections');
select ok(not has_function_privilege('anon', 'public.rename_saved_collection(uuid,text,text)', 'EXECUTE'), 'anon cannot rename collections');
select ok(not has_function_privilege('anon', 'public.set_place_collections(text,uuid,uuid[])', 'EXECUTE'), 'anon cannot update collection membership');
select ok(not has_function_privilege('anon', 'public.set_review_vote(uuid,integer)', 'EXECUTE'), 'anon cannot react to reviews');
select ok(not has_function_privilege('anon', 'public.submit_guide(text,text,text,text,jsonb,jsonb,text)', 'EXECUTE'), 'anon cannot submit Guides');
select ok(not has_function_privilege('anon', 'public.toggle_spot_upvote(uuid)', 'EXECUTE'), 'anon cannot vote on Spots');
select ok(not has_function_privilege('anon', 'public.check_saved_collection_item_ownership()', 'EXECUTE'), 'trigger implementation is not an anonymous RPC');

select ok(has_function_privilege('authenticated', 'public.admin_moderate_guide_revision(uuid,text,text,integer)', 'EXECUTE'), 'authenticated Admin guard remains callable');
select ok(has_function_privilege('authenticated', 'public.create_saved_collection(text,text)', 'EXECUTE'), 'authenticated collection create remains callable');
select ok(has_function_privilege('authenticated', 'public.delete_saved_collection(uuid)', 'EXECUTE'), 'authenticated collection delete remains callable');
select ok(has_function_privilege('authenticated', 'public.fetch_collection_places(uuid)', 'EXECUTE'), 'authenticated collection read remains callable');
select ok(has_function_privilege('authenticated', 'public.fetch_saved_route_candidates(uuid)', 'EXECUTE'), 'authenticated route candidates remain callable');
select ok(has_function_privilege('authenticated', 'public.list_my_guide_submissions()', 'EXECUTE'), 'authenticated Guide history remains callable');
select ok(has_function_privilege('authenticated', 'public.list_my_saved_collections()', 'EXECUTE'), 'authenticated collection list remains callable');
select ok(has_function_privilege('authenticated', 'public.rename_saved_collection(uuid,text,text)', 'EXECUTE'), 'authenticated collection rename remains callable');
select ok(has_function_privilege('authenticated', 'public.set_place_collections(text,uuid,uuid[])', 'EXECUTE'), 'authenticated collection membership remains callable');
select ok(has_function_privilege('authenticated', 'public.set_review_vote(uuid,integer)', 'EXECUTE'), 'authenticated review reactions remain callable');
select ok(has_function_privilege('authenticated', 'public.submit_guide(text,text,text,text,jsonb,jsonb,text)', 'EXECUTE'), 'authenticated Guide submit remains callable');
select ok(has_function_privilege('authenticated', 'public.toggle_spot_upvote(uuid)', 'EXECUTE'), 'authenticated Spot voting remains callable');

select ok(has_function_privilege('anon', 'public.list_active_discounts(uuid)', 'EXECUTE'), 'public active discounts remain callable');
select ok(has_function_privilege('authenticated', 'public.list_active_discounts(uuid)', 'EXECUTE'), 'authenticated active discounts remain callable');

select * from finish();
rollback;
