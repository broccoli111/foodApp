# Kitchen Compass native iOS roadmap

## Supabase integration

- Move session storage from `UserDefaults` to Keychain.
- Add refresh-token rotation handling in the Swift Supabase client.
- Persist generated shopping lists back to `shopping_list_items` after meal-plan generation.
- Add full edit/delete flows for recipes, meal plans, stores, sale items, and shopping list rows.
- Add storage upload helpers for `recipe-images` and `scan-uploads` buckets.

## Scanning

- Replace mocked scan parsing with VisionKit / Vision OCR for receipt and recipe images.
- Store scan jobs in `scan_jobs` and sync review decisions.
- Add camera capture flow in addition to PhotosPicker.

## Native iOS polish

- Add haptics to high-value actions.
- Add loading skeletons and empty states for live Supabase data.
- Add widgets or Live Activities for current shopping list if useful.
- Add AppIcon and launch-screen assets.

## Testing

- Add XCTest unit tests for normalization, recommendation scoring, sale matching, and shopping list generation.
- Add integration tests for Supabase DTO encoding/decoding.
- Add UI tests for onboarding, pantry add, recipe add, and shopping list flows.

## Production backend

- Add household invitations and multi-member role management.
- Add sale ingestion pipeline for manual import / Flipp / retailer circular sources.
- Add database functions for server-side shopping list persistence if client logic grows too complex.
