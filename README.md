# Kitchen Compass

Kitchen Compass is now a pure native iOS app built with SwiftUI and a Supabase backend.

Positioning: **Cook from what we have. Buy what is missing where it makes sense.**

## Project layout

```text
ios-native/                 Native SwiftUI iOS app and Xcode project
supabase/                   Supabase schema migrations, RLS, storage, seed setup
TODO.md                     Native iOS production roadmap
```

There is no Expo or React Native runtime required.

## Open and run on iPhone

1. Clone/pull this branch.
2. Open the native Xcode project:

```bash
open ios-native/KitchenCompass.xcodeproj
```

3. In Xcode, select the `KitchenCompass` target.
4. Go to **Signing & Capabilities**.
5. Select your Apple Developer team.
6. Change the bundle identifier if Xcode asks for a unique one, for example:

```text
com.yourname.kitchencompass
```

7. Connect your iPhone, select it as the run destination, and press **Cmd+R**.

## Supabase configuration

The hosted Supabase project is already set up:

```text
Project: FoodApp
URL: https://ohjezigyqrhkykbjimgo.supabase.co
```

Add the public publishable key in:

```text
ios-native/KitchenCompass/Resources/SupabaseConfig.plist
```

Set:

```xml
<key>SUPABASE_PUBLISHABLE_KEY</key>
<string>YOUR_SUPABASE_PUBLISHABLE_KEY</string>
```

Get the key from Supabase Dashboard -> FoodApp -> Project Settings -> API.

Do not commit secret service-role keys. The iOS app should only use the public publishable/anon key.

## Native app features

- SwiftUI tab app: Home, Pantry, Recipes, Plan, Shopping, Scan
- Native iOS navigation, forms, tab bar, and card UI
- Supabase email signup/sign-in through REST auth endpoints
- Persisted Supabase session in local app storage
- Supabase PostgREST calls for household data
- Recipe import from online URLs and Instagram/Reels descriptions
- Household-scoped pantry, recipes, ingredients, meal plans, shopping list, stores, and sale items
- Pantry add/consume/delete with Supabase persistence when signed in
- Recipe add and meal planning with Supabase persistence when signed in
- Recommendation engine and shopping-list generation in Swift
- Mock scan parsing layer ready for VisionKit/OCR replacement

## Backend status

The Supabase backend migrations have been applied to `FoodApp`:

- `initial_schema`
- `backend_setup`
- `seed_household_defaults`
- `harden_supabase_policies`

Security advisors are clean. Remaining performance advisor notices may mention unused indexes while the database is empty; those indexes are intentional for household-scoped queries and FK coverage.
