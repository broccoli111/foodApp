-- Kitchen Compass backend automation and storage setup.
-- This migration completes the Supabase backend beyond the core tables:
-- - creates private storage buckets for recipe images and scan uploads
-- - scopes storage objects by household folder
-- - creates a default one-household-per-user profile on signup

create or replace function public.is_storage_household_path(object_name text)
returns boolean
language sql
security definer
set search_path = public, storage
stable
as $$
  with folder as (
    select (storage.foldername(object_name))[1] as household_id_text
  )
  select case
    when coalesce(household_id_text, '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then household_id_text::uuid in (select public.user_household_ids())
    else false
  end
  from folder;
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('recipe-images', 'recipe-images', false, 10485760, array['image/png', 'image/jpeg', 'image/webp']),
  ('scan-uploads', 'scan-uploads', false, 10485760, array['image/png', 'image/jpeg', 'image/webp', 'application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "household members can read kitchen storage" on storage.objects;
drop policy if exists "household members can insert kitchen storage" on storage.objects;
drop policy if exists "household members can update kitchen storage" on storage.objects;
drop policy if exists "household members can delete kitchen storage" on storage.objects;

create policy "household members can read kitchen storage"
  on storage.objects for select
  to authenticated
  using (
    bucket_id in ('recipe-images', 'scan-uploads')
    and public.is_storage_household_path(name)
  );

create policy "household members can insert kitchen storage"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id in ('recipe-images', 'scan-uploads')
    and public.is_storage_household_path(name)
  );

create policy "household members can update kitchen storage"
  on storage.objects for update
  to authenticated
  using (
    bucket_id in ('recipe-images', 'scan-uploads')
    and public.is_storage_household_path(name)
  )
  with check (
    bucket_id in ('recipe-images', 'scan-uploads')
    and public.is_storage_household_path(name)
  );

create policy "household members can delete kitchen storage"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id in ('recipe-images', 'scan-uploads')
    and public.is_storage_household_path(name)
  );

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
