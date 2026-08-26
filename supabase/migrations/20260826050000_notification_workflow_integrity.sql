begin;

create or replace function private.notify_guide_decision()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare recipient uuid;
begin
  select creator_id into recipient
  from public.guides where id = new.guide_id;
  perform private.create_notification(
    recipient,
    'guide_' || new.decision,
    case when new.decision = 'approved'
      then 'Guide approved' else 'Guide needs changes' end,
    new.reason,
    'guide',
    new.guide_id
  );
  return new;
end;
$$;

revoke all on function private.notify_guide_decision()
  from public, anon, authenticated;

create trigger guide_decision_notification
after insert on public.guide_moderation_decisions
for each row execute function private.notify_guide_decision();

-- Keep reporter outcomes and affected-author outcomes aligned for every
-- reportable content type, including guides added after the original trigger.
create or replace function private.notify_report_decision()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare moderation_case public.moderation_cases;
declare author_id uuid;
begin
  select * into moderation_case from public.moderation_cases
  where id = new.case_id;
  perform private.create_notification(
    moderation_case.reporter_id, 'report_' || new.decision,
    'Report reviewed',
    case new.decision
      when 'upheld' then 'The reported content was actioned.'
      when 'dismissed' then 'The report was reviewed and dismissed.'
      else 'The report was escalated for further review.'
    end,
    moderation_case.target_type, moderation_case.target_id
  );
  if new.decision = 'upheld' then
    if moderation_case.target_type = 'review' then
      select user_id into author_id from public.reviews
      where id = moderation_case.target_id;
    elsif moderation_case.target_type = 'spot' then
      select owner_id into author_id from public.spots
      where id = moderation_case.target_id;
    elsif moderation_case.target_type = 'restaurant' then
      select owner_id into author_id from public.restaurants
      where id = moderation_case.target_id;
    elsif moderation_case.target_type = 'guide' then
      select creator_id into author_id from public.guides
      where id = moderation_case.target_id;
    end if;
    perform private.create_notification(
      author_id, 'content_moderated', 'Content moderation action',
      new.reason, moderation_case.target_type, moderation_case.target_id
    );
  end if;
  return new;
end;
$$;

revoke all on function private.notify_report_decision()
  from public, anon, authenticated;

commit;
