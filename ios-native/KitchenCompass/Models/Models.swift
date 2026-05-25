import Foundation

typealias EntityID = String

enum PantryLocation: String, Codable, CaseIterable, Identifiable {
    case pantry, fridge, freezer, spice, other
    var id: String { rawValue }
}

enum RecipeSourceType: String, Codable {
    case manual, url, scan
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
}

enum SaleSource: String, Codable {
    case manual, flipp, retailerCircular = "retailer_circular", `import`, mock
}

struct Household: Identifiable, Codable {
    var id: EntityID
    var name: String
}

struct PantryItem: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var householdID: EntityID
    var name: String
    var normalizedName: String
    var category: String
    var quantity: Double
    var unit: String
    var expirationDate: Date?
    var location: PantryLocation
    var notes: String?
    var lowStockThreshold: Double?
}

struct Recipe: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var householdID: EntityID
    var title: String
    var description: String
    var imageURL: URL?
    var sourceType: RecipeSourceType
    var sourceURL: URL?
    var servings: Int
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var instructions: [String]
    var tags: [String]
    var favorite: Bool
    var ingredients: [RecipeIngredient]
}

struct RecipeIngredient: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var recipeID: EntityID
    var rawText: String
    var name: String
    var normalizedName: String
    var quantity: Double
    var unit: String
    var category: String
    var optional: Bool
}

struct MealPlan: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var householdID: EntityID
    var recipeID: EntityID
    var plannedDate: Date
    var mealType: MealType
    var servings: Int
}

struct ShoppingListItem: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var householdID: EntityID
    var name: String
    var normalizedName: String
    var quantityNeeded: Double
    var unit: String
    var category: String
    var recommendedStoreID: EntityID?
    var matchedSaleItemID: EntityID?
    var checked: Bool
}

struct Store: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var householdID: EntityID
    var name: String
    var chain: String
    var preferred: Bool
    var zipCode: String?
}

struct SaleItem: Identifiable, Codable, Hashable {
    var id: EntityID = UUID().uuidString
    var storeID: EntityID
    var householdID: EntityID
    var itemName: String
    var normalizedName: String
    var category: String
    var salePrice: Double?
    var saleDescription: String
    var startDate: Date?
    var endDate: Date?
    var source: SaleSource
    var confidence: Double
}

struct SaleMatch: Hashable {
    var saleItem: SaleItem
    var store: Store
    var savingsScore: Double
}

struct RecipeRecommendation: Identifiable, Hashable {
    var id: EntityID { recipeID }
    var recipeID: EntityID
    var score: Int
    var matchPercent: Int
    var pantryItemsUsed: [PantryItem]
    var missingItems: [RecipeIngredient]
    var saleMatches: [SaleMatch]
    var reasons: [String]
    var badges: [String]
}

struct StoreRecommendation: Identifiable, Hashable {
    var id: EntityID { store.id }
    var store: Store
    var coveredItems: [ShoppingListItem]
    var saleMatches: [SaleMatch]
    var score: Double
    var summary: String
}

struct ParsedReceiptItem: Identifiable, Hashable {
    var id: EntityID = UUID().uuidString
    var rawText: String
    var normalizedName: String
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var confidence: Double
    var approved: Bool
}
