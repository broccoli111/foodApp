# Kitchen Compass native iOS app

This is the primary Kitchen Compass app. It is a pure SwiftUI iOS project with direct Supabase backend calls.

## Run locally

1. Open `KitchenCompass.xcodeproj` in Xcode.
2. Select the `KitchenCompass` target.
3. Pick your Apple Developer team under **Signing & Capabilities**.
4. Change the bundle identifier if needed.
5. Add your Supabase publishable key to `KitchenCompass/Resources/SupabaseConfig.plist`.
6. Connect your iPhone and press **Cmd+R**.

## Backend calls

`Services/SupabaseClient.swift` uses only native Foundation networking:

- Supabase Auth REST endpoints for sign up/sign in
- PostgREST endpoints for household data
- Public publishable key from `SupabaseConfig.plist`
- User access token for authenticated household-scoped requests

No Expo, React Native, JavaScript runtime, or third-party Swift package is required.

## Supabase data flow

After sign-in/sign-up, `KitchenStore.refreshFromSupabase()` loads:

- profile
- default household
- pantry items
- recipes and ingredients
- meal plans
- shopping list items
- stores
- sale items

Recipe importing:

- Enter a normal recipe URL to parse structured JSON-LD recipe data when available.
- Enter an Instagram/Reels URL to import from the post description/caption metadata when available.
- Review imported title, ingredients, and instructions before saving.

Writes currently covered from the native UI:

- add pantry item
- consume/update pantry item quantity
- delete pantry item
- add recipe with ingredients
- add meal plan item
- toggle persisted shopping list items

Local generated recommendations and shopping lists remain deterministic Swift logic so they work offline and are explainable.

## Receipt confirmation sheet

The Pantry toolbar includes a receipt scan icon. After receipt processing, Kitchen Compass presents a bottom sheet with one row per extracted item. Users can select/deselect each item and edit the item name and count before adding selected rows to pantry.
