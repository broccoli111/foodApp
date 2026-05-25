-- Kitchen Compass initial schema
-- Users can only read/write household-owned rows when they are members of that household.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  default_household_id uuid references public.households(id) on delete set null,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'adult', 'viewer')),
  created_at timestamptz not null default now(),
  unique (household_id, user_id)
);

create table if not exists public.pantry_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  category text not null default 'other',
  quantity numeric not null default 1 check (quantity >= 0),
  unit text not null default 'ct',
  expiration_date date,
  location text not null default 'pantry' check (location in ('pantry', 'fridge', 'freezer', 'spice', 'other')),
  notes text,
  low_stock_threshold numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  title text not null,
  description text not null default '',
  image_url text,
  source_type text not null default 'manual' check (source_type in ('manual', 'url', 'scan')),
  source_url text,
  servings integer not null default 4 check (servings > 0),
  prep_time_minutes integer not null default 0 check (prep_time_minutes >= 0),
  cook_time_minutes integer not null default 0 check (cook_time_minutes >= 0),
  instructions text[] not null default '{}',
  tags text[] not null default '{}',
  favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  raw_text text not null,
  name text not null,
  normalized_name text not null,
  quantity numeric not null default 1 check (quantity >= 0),
  unit text not null default 'ct',
  category text not null default 'other',
  optional boolean not null default false
);

create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  planned_date date not null,
  meal_type text not null default 'dinner' check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  servings integer not null default 4 check (servings > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  quantity_needed numeric not null default 1 check (quantity_needed >= 0),
  unit text not null default 'ct',
  category text not null default 'other',
  recommended_store_id uuid,
  matched_sale_item_id uuid,
  checked boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  chain text not null,
  preferred boolean not null default false,
  zip_code text,
  created_at timestamptz not null default now()
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  item_name text not null,
  normalized_name text not null,
  category text not null default 'other',
  sale_price numeric,
  sale_description text not null,
  start_date date,
  end_date date,
  source text not null default 'mock' check (source in ('manual', 'flipp', 'retailer_circular', 'import', 'mock')),
  confidence numeric not null default 0.75 check (confidence >= 0 and confidence <= 1),
  created_at timestamptz not null default now()
);

alter table public.shopping_list_items
  add constraint shopping_recommended_store_fk foreign key (recommended_store_id) references public.stores(id) on delete set null,
  add constraint shopping_matched_sale_fk foreign key (matched_sale_item_id) references public.sale_items(id) on delete set null;

create table if not exists public.scan_jobs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  type text not null check (type in ('recipe', 'receipt')),
  status text not null default 'draft' check (status in ('draft', 'processing', 'needs_review', 'approved', 'failed')),
  source_uri text,
  raw_text text,
  result_json jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists household_members_user_idx on public.household_members(user_id);
create index if not exists pantry_household_idx on public.pantry_items(household_id);
create index if not exists pantry_normalized_idx on public.pantry_items(household_id, normalized_name);
create index if not exists recipes_household_idx on public.recipes(household_id);
create index if not exists recipe_ingredients_recipe_idx on public.recipe_ingredients(recipe_id);
create index if not exists meal_plans_household_date_idx on public.meal_plans(household_id, planned_date);
create index if not exists shopping_household_checked_idx on public.shopping_list_items(household_id, checked);
create index if not exists sale_items_household_normalized_idx on public.sale_items(household_id, normalized_name);

create trigger households_updated_at before update on public.households for each row execute function public.set_updated_at();
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger pantry_items_updated_at before update on public.pantry_items for each row execute function public.set_updated_at();
create trigger recipes_updated_at before update on public.recipes for each row execute function public.set_updated_at();
create trigger scan_jobs_updated_at before update on public.scan_jobs for each row execute function public.set_updated_at();

create or replace function public.user_household_ids()
returns setof uuid
language sql
security definer
set search_path = public
stable
as $$
  select household_id from public.household_members where user_id = auth.uid()
$$;

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.pantry_items enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.meal_plans enable row level security;
alter table public.shopping_list_items enable row level security;
alter table public.stores enable row level security;
alter table public.sale_items enable row level security;
alter table public.scan_jobs enable row level security;

create policy "profiles are self accessible" on public.profiles for select using (id = auth.uid());
create policy "profiles are self insertable" on public.profiles for insert with check (id = auth.uid());
create policy "profiles are self updateable" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy "households visible to members" on public.households for select using (id in (select public.user_household_ids()));
create policy "households insertable by authenticated users" on public.households for insert to authenticated with check (true);
create policy "households updateable by members" on public.households for update using (id in (select public.user_household_ids())) with check (id in (select public.user_household_ids()));

create policy "members visible to household members" on public.household_members for select using (household_id in (select public.user_household_ids()) or user_id = auth.uid());
create policy "members can create own membership" on public.household_members for insert with check (user_id = auth.uid());
create policy "members can update own membership" on public.household_members for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "pantry household access" on public.pantry_items for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));
create policy "recipes household access" on public.recipes for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));
create policy "meal plans household access" on public.meal_plans for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));
create policy "shopping household access" on public.shopping_list_items for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));
create policy "stores household access" on public.stores for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));
create policy "sales household access" on public.sale_items for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));
create policy "scan jobs household access" on public.scan_jobs for all using (household_id in (select public.user_household_ids())) with check (household_id in (select public.user_household_ids()));

create policy "recipe ingredients through household recipes" on public.recipe_ingredients
  for all
  using (exists (select 1 from public.recipes r where r.id = recipe_id and r.household_id in (select public.user_household_ids())))
  with check (exists (select 1 from public.recipes r where r.id = recipe_id and r.household_id in (select public.user_household_ids())));
