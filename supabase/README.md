# Supabase backend setup

This directory contains the Supabase backend for Kitchen Compass.

## Hosted project

The migrations have been applied to the Supabase project `FoodApp` (`ohjezigyqrhkykbjimgo`).

Project API URL:

```text
https://ohjezigyqrhkykbjimgo.supabase.co
```

Use Supabase Dashboard -> Project Settings -> API to retrieve the public publishable key for the native iOS app. Do not commit service-role keys.

## Local development

Install the Supabase CLI and Docker, then run from the repository root:

```bash
supabase start
supabase db reset
supabase status
```

Generate database types manually if needed for documentation or future tooling:

```bash
supabase gen types typescript --local --schema public
```

## Backend behavior

- New auth users automatically get one profile, one household, and one owner membership.
- New households automatically get default stores and mock sale data.
- Household data is protected by RLS through `household_members`.
- Private storage buckets exist for:
  - `recipe-images`
  - `scan-uploads`
- Storage object paths must start with a household UUID folder:

```text
<household_id>/<user_id>/<filename>
```

Security advisors are clean after the hardening migration.
