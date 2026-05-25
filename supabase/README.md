# Supabase backend setup

This directory is a complete Supabase backend package for Kitchen Compass.

## Local development

The Supabase CLI requires Docker for local development.

```bash
npm install
npm run supabase:start
npm run supabase:reset
npm run supabase:status
```

After `supabase:start`, copy the local API URL and anon key into `.env`:

```bash
EXPO_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
EXPO_PUBLIC_SUPABASE_ANON_KEY=<local anon key from supabase status>
```

Generate local types after migrations are applied:

```bash
npm run supabase:types
```

## Hosted project deployment

This environment did not include deployment credentials, so remote deployment must be run from a machine/session with Supabase credentials.

```bash
export SUPABASE_ACCESS_TOKEN=<personal access token>
export SUPABASE_PROJECT_REF=<project ref>
export SUPABASE_DB_PASSWORD=<database password>

npx supabase login --token "$SUPABASE_ACCESS_TOKEN"
npx supabase link --project-ref "$SUPABASE_PROJECT_REF"
npx supabase db push
npx supabase gen types typescript --project-id "$SUPABASE_PROJECT_REF" --schema public > lib/supabase/database.ts
```

Then update app environment values with the hosted project URL and anon key.

## Backend behavior

- Email auth is enabled in `supabase/config.toml` for local development.
- New auth users automatically get:
  - one `profiles` row
  - one default `households` row
  - one owner `household_members` row
- Household data is protected by RLS through `household_members`.
- Private storage buckets are created for:
  - `recipe-images`
  - `scan-uploads`
- Storage object paths must start with a household UUID folder:

```text
<household_id>/<user_id>/<filename>
```

Example:

```text
7c0a2c4d-2c29-42bb-9a76-8c2cfaf6d829/user-id/receipt-2026-05-25.jpg
```

The path convention lets storage RLS verify household membership.
