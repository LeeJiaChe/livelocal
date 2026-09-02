begin;

-- Both Restaurant revision-save overloads inherited a stale write to a
-- decision_reason column that does not exist on restaurant_revisions. The
-- actual mutable draft field is duplicate_override_reason. Rebuild the exact
-- deployed definitions in place so the legacy contract and the identity-aware
-- v2 contract remain compatible without editing either deployed migration.
do $$
declare
  signature text;
  definition text;
  corrected text;
begin
  foreach signature in array array[
    'public.save_restaurant_revision_draft(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text)',
    'public.save_restaurant_revision_draft_v2(uuid,text,text,text,text,text,text,text,text,text,double precision,double precision,boolean,text,text,text)'
  ] loop
    select pg_get_functiondef(to_regprocedure(signature)) into definition;
    if definition is null then
      raise exception 'Required Restaurant revision function is missing: %', signature;
    end if;
    corrected := replace(
      replace(
        definition,
        'decision_reason = null',
        'duplicate_override_reason = null'
      ),
      'decision_reason=null',
      'duplicate_override_reason=null'
    );
    if corrected = definition then
      raise exception 'Expected stale decision_reason assignment was not found: %', signature;
    end if;
    execute corrected;
  end loop;
end;
$$;

commit;
