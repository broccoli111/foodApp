-- Seed default stores and mock sale data for every Kitchen Compass household.
-- These rows are household-scoped so RLS keeps each user's demo sale data private.

create or replace function public.seed_household_defaults(target_household_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  costco_id uuid;
  bjs_id uuid;
  stop_shop_id uuid;
  shoprite_id uuid;
  whole_foods_id uuid;
  trader_joes_id uuid;
begin
  insert into public.stores (household_id, name, chain, preferred, zip_code)
  values (target_household_id, 'Costco', 'Costco', true, null)
  returning id into costco_id;

  insert into public.stores (household_id, name, chain, preferred, zip_code)
  values (target_household_id, 'BJ''s', 'BJ''s', false, null)
  returning id into bjs_id;

  insert into public.stores (household_id, name, chain, preferred, zip_code)
  values (target_household_id, 'Stop & Shop', 'Stop & Shop', true, null)
  returning id into stop_shop_id;

  insert into public.stores (household_id, name, chain, preferred, zip_code)
  values (target_household_id, 'ShopRite', 'ShopRite', true, null)
  returning id into shoprite_id;

  insert into public.stores (household_id, name, chain, preferred, zip_code)
  values (target_household_id, 'Whole Foods', 'Whole Foods', false, null)
  returning id into whole_foods_id;

  insert into public.stores (household_id, name, chain, preferred, zip_code)
  values (target_household_id, 'Trader Joe''s', 'Trader Joe''s', true, null)
  returning id into trader_joes_id;

  insert into public.sale_items (store_id, household_id, item_name, normalized_name, category, sale_price, sale_description, start_date, end_date, source, confidence)
  values
    (shoprite_id, target_household_id, 'Boneless chicken breast', 'chicken breast', 'meat', 2.99, '$2.99/lb family pack', current_date, current_date + 7, 'mock', 0.94),
    (stop_shop_id, target_household_id, 'Large eggs', 'eggs', 'eggs', 2.49, '$2.49 dozen with card', current_date, current_date + 5, 'mock', 0.91),
    (shoprite_id, target_household_id, 'Barilla pasta', 'penne pasta', 'pasta', 1.25, '4 for $5 assorted pasta', current_date, current_date + 7, 'mock', 0.88),
    (costco_id, target_household_id, 'Milk 2 pack', 'milk', 'dairy', 5.99, 'Warehouse value on two gallons', current_date, current_date + 10, 'mock', 0.74),
    (trader_joes_id, target_household_id, 'Shredded cheese', 'cheese', 'dairy', 3.49, 'Everyday low price', null, null, 'mock', 0.70),
    (whole_foods_id, target_household_id, 'Avocados', 'avocado', 'produce', 1.50, 'Prime member produce special', current_date, current_date + 3, 'mock', 0.67);
end;
$$;

create or replace function public.seed_household_defaults_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.seed_household_defaults(new.id);
  return new;
end;
$$;

drop trigger if exists seed_household_defaults_after_insert on public.households;
create trigger seed_household_defaults_after_insert
  after insert on public.households
  for each row execute function public.seed_household_defaults_on_insert();

-- Backfill defaults for any households created before this migration.
select public.seed_household_defaults(h.id)
from public.households h
where not exists (
  select 1 from public.stores s where s.household_id = h.id
);
