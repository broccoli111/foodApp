# Kitchen Compass

Kitchen Compass is an iOS-first household meal-planning MVP built with Expo, React Native, Expo Router, TypeScript, NativeWind, Supabase, Zustand, and TanStack Query.

Positioning: **Cook from what we have. Buy what is missing where it makes sense.**

## What is included

- Expo Router tab navigation: Home, Pantry, Recipes, Plan, Shopping, Scan
- Supabase email-auth client with persistent session storage
- Household-oriented data model and SQL migrations with RLS policies
- Pantry inventory with manual add, quick add, search, location filtering, low-stock and expiring indicators
- Recipe library with inventory match percentages and recipe detail views
- Mocked recipe scanning flow with OCR/parser abstractions and review-before-save
- Mocked receipt scanning flow with editable approval and batch pantry add
- Deterministic ingredient normalization utilities
- Explainable weekly recommendation engine
- Weekly meal planner MVP
- Shopping list generation from meal plans with pantry subtraction and category grouping
- Mock sale/store data and store recommendation engine
- Warm, card-based mobile UI using NativeWind

## Getting started

```bash
npm install
cp .env.example .env
npm run start
```

Set the Supabase environment values in `.env` when connecting to a real project:

```bash
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

Run checks:

```bash
npm run typecheck
npm run lint
```

## Supabase setup

1. Create a Supabase project.
2. Apply `supabase/migrations/20260525143600_initial_schema.sql`.
3. Optionally run `supabase/seed.sql` for mock store/sale rows.
4. Generate real database types when the project is available:

```bash
supabase gen types typescript --project-id <project-id> --schema public > lib/supabase/database.ts
```

The included `lib/supabase/database.ts` is a generated-style type file so app development can continue before a live project exists.

## Architecture

```text
/app                 Expo Router routes
/components          Shared and feature UI components
/lib/constants       Categories, mock household data, theme tokens
/lib/providers       Query, safe-area, gesture, navigation providers
/lib/store           Zustand auth and kitchen stores
/lib/supabase        Supabase client and typed Database contract
/lib/types           Domain models
/lib/utils           Date helpers
/services            Inventory, recipes, recommendations, shopping, sales, scanning, normalization
/supabase            SQL migrations and seed data
```

## Notes

- OCR and LLM parsing are mocked behind replaceable interfaces in `services/scanService.ts`.
- Sale ingestion is mocked and modular. Instacart pricing is intentionally not used as authoritative pricing.
- The app uses local persisted mock data for the MVP UI while the Supabase schema/auth layer is ready for real integration.


## Native iOS SwiftUI app

A native SwiftUI version is available in `ios-native/`. Open `ios-native/KitchenCompass.xcodeproj` in Xcode, choose your Apple development team under Signing & Capabilities, connect your iPhone, and press Run. Configure live Supabase auth by adding the FoodApp publishable key to `ios-native/KitchenCompass/Resources/SupabaseConfig.plist`.
