-- Local development seed for Kitchen Compass.
-- Store and sale defaults are created by the seed_household_defaults trigger
-- whenever a household is inserted.

insert into public.households (id, name)
values ('00000000-0000-0000-0000-000000000101', 'Demo Kitchen Compass Home')
on conflict (id) do nothing;
