-- Mock sale/store data for a local demo household.
-- For a real user, create a household through onboarding and duplicate these rows for that household.

insert into public.households (id, name)
values ('00000000-0000-0000-0000-000000000101', 'Demo Kitchen Compass Home')
on conflict (id) do nothing;

insert into public.stores (id, household_id, name, chain, preferred, zip_code) values
  ('00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000101', 'Costco', 'Costco', true, '07030'),
  ('00000000-0000-0000-0000-000000001002', '00000000-0000-0000-0000-000000000101', 'BJ''s', 'BJ''s', false, '07030'),
  ('00000000-0000-0000-0000-000000001003', '00000000-0000-0000-0000-000000000101', 'Stop & Shop', 'Stop & Shop', true, '07030'),
  ('00000000-0000-0000-0000-000000001004', '00000000-0000-0000-0000-000000000101', 'ShopRite', 'ShopRite', true, '07030'),
  ('00000000-0000-0000-0000-000000001005', '00000000-0000-0000-0000-000000000101', 'Whole Foods', 'Whole Foods', false, '07030'),
  ('00000000-0000-0000-0000-000000001006', '00000000-0000-0000-0000-000000000101', 'Trader Joe''s', 'Trader Joe''s', true, '07030')
on conflict (id) do nothing;

insert into public.sale_items (store_id, household_id, item_name, normalized_name, category, sale_price, sale_description, start_date, end_date, source, confidence) values
  ('00000000-0000-0000-0000-000000001004', '00000000-0000-0000-0000-000000000101', 'Boneless chicken breast', 'chicken breast', 'meat', 2.99, '$2.99/lb family pack', current_date, current_date + 7, 'mock', 0.94),
  ('00000000-0000-0000-0000-000000001003', '00000000-0000-0000-0000-000000000101', 'Large eggs', 'eggs', 'eggs', 2.49, '$2.49 dozen with card', current_date, current_date + 5, 'mock', 0.91),
  ('00000000-0000-0000-0000-000000001004', '00000000-0000-0000-0000-000000000101', 'Barilla pasta', 'penne pasta', 'pasta', 1.25, '4 for $5 assorted pasta', current_date, current_date + 7, 'mock', 0.88),
  ('00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000000101', 'Milk 2 pack', 'milk', 'dairy', 5.99, 'Warehouse value on two gallons', current_date, current_date + 10, 'mock', 0.74),
  ('00000000-0000-0000-0000-000000001006', '00000000-0000-0000-0000-000000000101', 'Shredded cheese', 'cheese', 'dairy', 3.49, 'Everyday low price', null, null, 'mock', 0.70),
  ('00000000-0000-0000-0000-000000001005', '00000000-0000-0000-0000-000000000101', 'Avocados', 'avocado', 'produce', 1.50, 'Prime member produce special', current_date, current_date + 3, 'mock', 0.67);
