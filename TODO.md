# Kitchen Compass roadmap

## Production data integration

- Replace local Zustand mock persistence with Supabase query/mutation hooks per household table.
- Add household creation during onboarding and future invite/member management.
- Generate Supabase types from the live project and remove the handwritten generated-style fallback.
- Add storage buckets and policies for recipe images and scan uploads.

## Scanning intelligence

- Swap `MockOcrProvider` for an OCR provider such as Apple Vision, Google Vision, or a secure backend OCR pipeline.
- Add an LLM parser implementation behind `RecipeParser` and `ReceiptParser` interfaces.
- Store scan jobs and review decisions in `scan_jobs` for auditability and retries.

## Meal planning UX

- Replace tap-to-add planner with gesture-based drag/drop using Reanimated and Gesture Handler.
- Add breakfast/lunch/dinner/snack filters and leftovers.
- Support recurring favorites and family preference constraints.

## Recommendation engine

- Add unit-aware pantry sufficiency checks for equivalent units.
- Add household preferences, disliked ingredients, dietary tags, and time-budget constraints.
- Persist recommendation snapshots so explanations are stable across a planning session.

## Shopping and sales

- Build modular sale ingestion jobs for Flipp/import/manual retailer circular data.
- Add savings thresholds to avoid extra trips for tiny discounts.
- Add purchased-item reconciliation back into pantry with expiration suggestions.

## Quality and release

- Add unit tests for normalization, recommendation scoring, shopping generation, and sale matching.
- Add E2E coverage for scan review, meal planning, and shopping generation.
- Add error boundaries, skeleton loading states, and offline sync conflict handling.
- Configure EAS build profiles and app icons/splash assets.
