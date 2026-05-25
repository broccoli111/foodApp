-- Harden RLS helper functions and policies after initial backend setup.
-- Internal SECURITY DEFINER functions live in a non-exposed private schema.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function private.user_household_ids()
returns setof uuid
language sql
security definer
set search_path = public
stable
as $$
  select household_id from public.household_members where user_id = (select auth.uid())
$$;

create or replace function private.is_storage_household_path(object_name text)
returns boolean
language sql
security definer
set search_path = public, storage, private
stable
as $$
  with folder as (
    select (storage.foldername(object_name))[1] as household_id_text
  )
  select case
    when coalesce(household_id_text, '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then household_id_text::uuid in (select private.user_household_ids())
    else false
  end
  from folder;
$$;

create or replace function private.seed_household_defaults(target_household_id uuid)
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
  if exists (select 1 from public.stores where household_id = target_household_id) then
    return;
  end if;

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

create or replace function private.seed_household_defaults_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
begin
  perform private.seed_household_defaults(new.id);
  return new;
end;
$$;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  new_household_id uuid;
  household_name text;
begin
  household_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'household_name', ''),
    case
      when new.raw_user_meta_data ? 'full_name' then (new.raw_user_meta_data ->> 'full_name') || '''s Kitchen'
      when new.email is not null then split_part(new.email, '@', 1) || '''s Kitchen'
      else 'My Kitchen'
    end
  );

  insert into public.households (name)
  values (household_name)
  returning id into new_household_id;

  insert into public.profiles (id, email, full_name, default_household_id, onboarding_completed)
  values (
    new.id,
    coalesce(new.email, ''),
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    new_household_id,
    false
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    default_household_id = coalesce(public.profiles.default_household_id, excluded.default_household_id),
    updated_at = now();

  insert into public.household_members (household_id, user_id, role)
  values (new_household_id, new.id, 'owner')
  on conflict (household_id, user_id) do nothing;

  return new;
end;
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;
revoke all on function private.seed_household_defaults(uuid) from public, anon, authenticated;
revoke all on function private.seed_household_defaults_on_insert() from public, anon, authenticated;
grant execute on function private.user_household_ids() to authenticated;
grant execute on function private.is_storage_household_path(text) to authenticated;

-- Replace policies to use private helpers and optimized auth.uid calls.
drop policy if exists "profiles are self accessible" on public.profiles;
drop policy if exists "profiles are self insertable" on public.profiles;
drop policy if exists "profiles are self updateable" on public.profiles;
create policy "profiles are self accessible" on public.profiles for select using (id = (select auth.uid()));
create policy "profiles are self insertable" on public.profiles for insert with check (id = (select auth.uid()));
create policy "profiles are self updateable" on public.profiles for update using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "households visible to members" on public.households;
drop policy if exists "households insertable by authenticated users" on public.households;
drop policy if exists "households updateable by members" on public.households;
create policy "households visible to members" on public.households for select using (id in (select private.user_household_ids()));
create policy "households updateable by members" on public.households for update using (id in (select private.user_household_ids())) with check (id in (select private.user_household_ids()));

drop policy if exists "members visible to household members" on public.household_members;
drop policy if exists "members can create own membership" on public.household_members;
drop policy if exists "members can update own membership" on public.household_members;
create policy "members visible to household members" on public.household_members for select using (household_id in (select private.user_household_ids()) or user_id = (select auth.uid()));

drop policy if exists "pantry household access" on public.pantry_items;
drop policy if exists "recipes household access" on public.recipes;
drop policy if exists "meal plans household access" on public.meal_plans;
drop policy if exists "shopping household access" on public.shopping_list_items;
drop policy if exists "stores household access" on public.stores;
drop policy if exists "sales household access" on public.sale_items;
drop policy if exists "scan jobs household access" on public.scan_jobs;
drop policy if exists "recipe ingredients through household recipes" on public.recipe_ingredients;

create policy "pantry household access" on public.pantry_items for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));
create policy "recipes household access" on public.recipes for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));
create policy "meal plans household access" on public.meal_plans for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));
create policy "shopping household access" on public.shopping_list_items for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));
create policy "stores household access" on public.stores for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));
create policy "sales household access" on public.sale_items for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));
create policy "scan jobs household access" on public.scan_jobs for all using (household_id in (select private.user_household_ids())) with check (household_id in (select private.user_household_ids()));

create policy "recipe ingredients through household recipes" on public.recipe_ingredients
  for all
  using (exists (select 1 from public.recipes r where r.id = recipe_id and r.household_id in (select private.user_household_ids())))
  with check (exists (select 1 from public.recipes r where r.id = recipe_id and r.household_id in (select private.user_household_ids())));

-- Replace storage policies to use private helper.
drop policy if exists "household members can read kitchen storage" on storage.objects;
drop policy if exists "household members can insert kitchen storage" on storage.objects;
drop policy if exists "household members can update kitchen storage" on storage.objects;
drop policy if exists "household members can delete kitchen storage" on storage.objects;

create policy "household members can read kitchen storage"
  on storage.objects for select to authenticated
  using (bucket_id in ('recipe-images', 'scan-uploads') and private.is_storage_household_path(name));

create policy "household members can insert kitchen storage"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('recipe-images', 'scan-uploads') and private.is_storage_household_path(name));

create policy "household members can update kitchen storage"
  on storage.objects for update to authenticated
  using (bucket_id in ('recipe-images', 'scan-uploads') and private.is_storage_household_path(name))
  with check (bucket_id in ('recipe-images', 'scan-uploads') and private.is_storage_household_path(name));

create policy "household members can delete kitchen storage"
  on storage.objects for delete to authenticated
  using (bucket_id in ('recipe-images', 'scan-uploads') and private.is_storage_household_path(name));

-- Repoint triggers at private functions.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

drop trigger if exists seed_household_defaults_after_insert on public.households;
create trigger seed_household_defaults_after_insert
  after insert on public.households
  for each row execute function private.seed_household_defaults_on_insert();

-- Foreign-key covering indexes flagged by Supabase advisors.
create index if not exists profiles_default_household_idx on public.profiles(default_household_id);
create index if not exists meal_plans_recipe_idx on public.meal_plans(recipe_id);
create index if not exists sale_items_store_idx on public.sale_items(store_id);
create index if not exists scan_jobs_household_idx on public.scan_jobs(household_id);
create index if not exists shopping_recommended_store_idx on public.shopping_list_items(recommended_store_id);
create index if not exists shopping_matched_sale_idx on public.shopping_list_items(matched_sale_item_id);
create index if not exists stores_household_idx on public.stores(household_id);

-- Remove exposed public helper functions after policies/triggers no longer depend on them.
drop function if exists public.handle_new_user();
drop function if exists public.is_storage_household_path(text);
drop function if exists public.seed_household_defaults(uuid);
drop function if exists public.seed_household_defaults_on_insert();
drop function if exists public.user_household_ids();
