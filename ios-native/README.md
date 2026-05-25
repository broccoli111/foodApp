# Kitchen Compass native iOS app

This folder contains a native SwiftUI version of Kitchen Compass that you can open in Xcode and run on an iPhone with your Apple developer account.

## Open in Xcode

1. Open `ios-native/KitchenCompass.xcodeproj` in Xcode.
2. Select the `KitchenCompass` target.
3. Set **Signing & Capabilities** to your Apple team.
4. Change the bundle identifier if needed, e.g. `com.yourname.kitchencompass`.
5. Connect your iPhone and select it as the run destination.
6. Press **Run**.

## Supabase configuration

The app reads Supabase settings from:

```text
KitchenCompass/Resources/SupabaseConfig.plist
```

The project URL is already set:

```text
https://ohjezigyqrhkykbjimgo.supabase.co
```

Add your publishable key in Xcode before testing live email auth:

```xml
<key>SUPABASE_PUBLISHABLE_KEY</key>
<string>YOUR_PUBLISHABLE_KEY</string>
```

Use the public publishable key from Supabase Dashboard -> FoodApp -> Project Settings -> API.

## What is native now

- SwiftUI tab app: Home, Pantry, Recipes, Plan, Shopping, Scan
- iOS-native card UI, forms, navigation, and tab bar
- Pantry inventory and quick add/edit-style actions
- Recipe library/detail/manual add
- Weekly recommendation scoring
- Meal planner
- Shopping list generation and sale-aware store guidance
- Mock receipt and recipe scanning flows
- Native PhotosPicker hook for image selection
- Supabase email auth REST client and config layer

## Continued production work

- Replace local `KitchenStore` arrays with Supabase PostgREST repositories.
- Store auth sessions securely in Keychain.
- Replace mocked OCR with VisionKit/Live Text or a backend OCR function.
- Add camera capture with `UIImagePickerController` or AVFoundation.
- Add XCTest coverage for normalization, recommendation scoring, and shopping list generation.
