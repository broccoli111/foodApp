import Foundation
import SwiftUI

@MainActor
final class KitchenStore: ObservableObject {
    @Published var household = Household(id: "household-demo", name: "Kitchen Compass Home")
    @Published var pantryItems: [PantryItem]
    @Published var recipes: [Recipe]
    @Published var mealPlans: [MealPlan]
    @Published var shoppingList: [ShoppingListItem] = []
    @Published var stores: [Store]
    @Published var saleItems: [SaleItem]
    @Published var authMessage: String?

    private let supabase = SupabaseClient()

    init() {
        let data = MockData.make()
        pantryItems = data.pantry
        recipes = data.recipes
        mealPlans = data.plans
        stores = data.stores
        saleItems = data.sales
    }

    var recommendations: [RecipeRecommendation] {
        RecommendationEngine.score(pantry: pantryItems, recipes: recipes, sales: saleItems, stores: stores)
    }

    var generatedShoppingList: [ShoppingListItem] {
        ShoppingListGenerator.generate(householdID: household.id, plans: mealPlans, recipes: recipes, pantry: pantryItems, sales: saleItems, stores: stores)
    }

    var activeShoppingList: [ShoppingListItem] {
        shoppingList.isEmpty ? generatedShoppingList : shoppingList
    }

    func addPantryItem(name: String, quantity: Double = 1, unit: String = "ct", location: PantryLocation = .pantry) {
        let normalized = IngredientNormalizer.normalize(name)
        pantryItems.insert(PantryItem(householdID: household.id, name: name, normalizedName: normalized, category: IngredientNormalizer.category(for: normalized), quantity: quantity, unit: unit, expirationDate: nil, location: location, notes: nil, lowStockThreshold: 1), at: 0)
    }

    func consume(_ item: PantryItem) {
        guard let index = pantryItems.firstIndex(of: item) else { return }
        pantryItems[index].quantity = max(0, pantryItems[index].quantity - 1)
    }

    func delete(_ item: PantryItem) {
        pantryItems.removeAll { $0.id == item.id }
    }

    func addRecipe(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
    }

    func addMeal(recipeID: EntityID, date: Date = Date().addingTimeInterval(86_400), mealType: MealType = .dinner) {
        guard let recipe = recipes.first(where: { $0.id == recipeID }) else { return }
        mealPlans.append(MealPlan(householdID: household.id, recipeID: recipe.id, plannedDate: date, mealType: mealType, servings: recipe.servings))
    }

    func regenerateShoppingList() {
        shoppingList = generatedShoppingList
    }

    func toggleShoppingItem(_ item: ShoppingListItem) {
        if shoppingList.isEmpty { shoppingList = generatedShoppingList }
        guard let index = shoppingList.firstIndex(where: { $0.id == item.id }) else { return }
        shoppingList[index].checked.toggle()
    }

    func approveReceiptItems(_ items: [ParsedReceiptItem]) {
        items.filter(\.approved).forEach { item in
            let location: PantryLocation = ["dairy", "eggs", "produce"].contains(item.category) ? .fridge : .pantry
            addPantryItem(name: item.name, quantity: item.quantity, unit: item.unit, location: location)
        }
    }

    func signIn(email: String, password: String) async {
        do {
            _ = try await supabase.signIn(email: email, password: password)
            authMessage = "Signed in. Live data sync can be enabled from the service layer."
        } catch {
            authMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        do {
            _ = try await supabase.signUp(email: email, password: password)
            authMessage = "Account created. Supabase created your household automatically."
        } catch {
            authMessage = error.localizedDescription
        }
    }
}
