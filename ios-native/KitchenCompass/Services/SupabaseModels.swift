import Foundation

struct SupabaseUser: Codable {
    let id: String
    let email: String?
}

struct SupabaseAuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct ProfileRow: Codable {
    let id: String
    let email: String
    let fullName: String?
    let defaultHouseholdID: String?
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case defaultHouseholdID = "default_household_id"
        case onboardingCompleted = "onboarding_completed"
    }
}

struct HouseholdRow: Codable {
    let id: String
    let name: String

    func model() -> Household {
        Household(id: id, name: name)
    }
}

struct PantryItemRow: Codable {
    let id: String
    let householdID: String
    let name: String
    let normalizedName: String
    let category: String
    let quantity: Double
    let unit: String
    let expirationDate: String?
    let location: String
    let notes: String?
    let lowStockThreshold: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, category, quantity, unit, location, notes
        case householdID = "household_id"
        case normalizedName = "normalized_name"
        case expirationDate = "expiration_date"
        case lowStockThreshold = "low_stock_threshold"
    }

    func model() -> PantryItem {
        PantryItem(
            id: id,
            householdID: householdID,
            name: name,
            normalizedName: normalizedName,
            category: category,
            quantity: quantity,
            unit: unit,
            expirationDate: Self.dateFormatter.date(from: expirationDate ?? ""),
            location: PantryLocation(rawValue: location) ?? .other,
            notes: notes,
            lowStockThreshold: lowStockThreshold
        )
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct PantryItemInsert: Codable {
    let householdID: String
    let name: String
    let normalizedName: String
    let category: String
    let quantity: Double
    let unit: String
    let expirationDate: String?
    let location: String
    let notes: String?
    let lowStockThreshold: Double?

    enum CodingKeys: String, CodingKey {
        case name, category, quantity, unit, location, notes
        case householdID = "household_id"
        case normalizedName = "normalized_name"
        case expirationDate = "expiration_date"
        case lowStockThreshold = "low_stock_threshold"
    }
}

struct QuantityPatch: Codable {
    let quantity: Double
}

struct RecipeRow: Codable {
    let id: String
    let householdID: String
    let title: String
    let description: String
    let imageURL: String?
    let sourceType: String
    let sourceURL: String?
    let servings: Int
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let instructions: [String]
    let tags: [String]
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description, servings, instructions, tags, favorite
        case householdID = "household_id"
        case imageURL = "image_url"
        case sourceType = "source_type"
        case sourceURL = "source_url"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
    }
}

struct RecipeInsert: Codable {
    let householdID: String
    let title: String
    let description: String
    let imageURL: String?
    let sourceType: String
    let sourceURL: String?
    let servings: Int
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let instructions: [String]
    let tags: [String]
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case title, description, servings, instructions, tags, favorite
        case householdID = "household_id"
        case imageURL = "image_url"
        case sourceType = "source_type"
        case sourceURL = "source_url"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
    }
}

struct RecipeIngredientRow: Codable {
    let id: String
    let recipeID: String
    let rawText: String
    let name: String
    let normalizedName: String
    let quantity: Double
    let unit: String
    let category: String
    let optional: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, category, optional
        case recipeID = "recipe_id"
        case rawText = "raw_text"
        case normalizedName = "normalized_name"
    }

    func model() -> RecipeIngredient {
        RecipeIngredient(id: id, recipeID: recipeID, rawText: rawText, name: name, normalizedName: normalizedName, quantity: quantity, unit: unit, category: category, optional: optional)
    }
}

struct RecipeIngredientInsert: Codable {
    let recipeID: String
    let rawText: String
    let name: String
    let normalizedName: String
    let quantity: Double
    let unit: String
    let category: String
    let optional: Bool

    enum CodingKeys: String, CodingKey {
        case name, quantity, unit, category, optional
        case recipeID = "recipe_id"
        case rawText = "raw_text"
        case normalizedName = "normalized_name"
    }
}

struct MealPlanRow: Codable {
    let id: String
    let householdID: String
    let recipeID: String
    let plannedDate: String
    let mealType: String
    let servings: Int

    enum CodingKeys: String, CodingKey {
        case id, servings
        case householdID = "household_id"
        case recipeID = "recipe_id"
        case plannedDate = "planned_date"
        case mealType = "meal_type"
    }

    func model() -> MealPlan {
        MealPlan(id: id, householdID: householdID, recipeID: recipeID, plannedDate: PantryItemRow.dateFormatter.date(from: plannedDate) ?? Date(), mealType: MealType(rawValue: mealType) ?? .dinner, servings: servings)
    }
}

struct MealPlanInsert: Codable {
    let householdID: String
    let recipeID: String
    let plannedDate: String
    let mealType: String
    let servings: Int

    enum CodingKeys: String, CodingKey {
        case servings
        case householdID = "household_id"
        case recipeID = "recipe_id"
        case plannedDate = "planned_date"
        case mealType = "meal_type"
    }
}

struct StoreRow: Codable {
    let id: String
    let householdID: String
    let name: String
    let chain: String
    let preferred: Bool
    let zipCode: String?

    enum CodingKeys: String, CodingKey {
        case id, name, chain, preferred
        case householdID = "household_id"
        case zipCode = "zip_code"
    }

    func model() -> Store {
        Store(id: id, householdID: householdID, name: name, chain: chain, preferred: preferred, zipCode: zipCode)
    }
}

struct SaleItemRow: Codable {
    let id: String
    let storeID: String
    let householdID: String
    let itemName: String
    let normalizedName: String
    let category: String
    let salePrice: Double?
    let saleDescription: String
    let startDate: String?
    let endDate: String?
    let source: String
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case id, category, source, confidence
        case storeID = "store_id"
        case householdID = "household_id"
        case itemName = "item_name"
        case normalizedName = "normalized_name"
        case salePrice = "sale_price"
        case saleDescription = "sale_description"
        case startDate = "start_date"
        case endDate = "end_date"
    }

    func model() -> SaleItem {
        SaleItem(
            id: id,
            storeID: storeID,
            householdID: householdID,
            itemName: itemName,
            normalizedName: normalizedName,
            category: category,
            salePrice: salePrice,
            saleDescription: saleDescription,
            startDate: PantryItemRow.dateFormatter.date(from: startDate ?? ""),
            endDate: PantryItemRow.dateFormatter.date(from: endDate ?? ""),
            source: SaleSource(rawValue: source) ?? .mock,
            confidence: confidence
        )
    }
}

struct ShoppingListItemRow: Codable {
    let id: String
    let householdID: String
    let name: String
    let normalizedName: String
    let quantityNeeded: Double
    let unit: String
    let category: String
    let recommendedStoreID: String?
    let matchedSaleItemID: String?
    let checked: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, unit, category, checked
        case householdID = "household_id"
        case normalizedName = "normalized_name"
        case quantityNeeded = "quantity_needed"
        case recommendedStoreID = "recommended_store_id"
        case matchedSaleItemID = "matched_sale_item_id"
    }

    func model() -> ShoppingListItem {
        ShoppingListItem(id: id, householdID: householdID, name: name, normalizedName: normalizedName, quantityNeeded: quantityNeeded, unit: unit, category: category, recommendedStoreID: recommendedStoreID, matchedSaleItemID: matchedSaleItemID, checked: checked)
    }
}

struct CheckedPatch: Codable {
    let checked: Bool
}
