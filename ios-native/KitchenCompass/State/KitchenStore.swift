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
    @Published var syncStatus = "Using local starter data"
    @Published var isSyncing = false
    @Published var isUsingLiveBackend = false

    private let supabase = SupabaseClient()

    init() {
        let data = MockData.make()
        pantryItems = data.pantry
        recipes = data.recipes
        mealPlans = data.plans
        stores = data.stores
        saleItems = data.sales

        if supabase.isAuthenticated {
            Task { await refreshFromSupabase() }
        }
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

    func refreshFromSupabase() async {
        guard supabase.hasPublishableKey else {
            syncStatus = "Add Supabase publishable key to enable live sync"
            isUsingLiveBackend = false
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let payload = try await supabase.loadKitchenData()
            apply(payload)
            syncStatus = "Synced with Supabase FoodApp"
            isUsingLiveBackend = true
        } catch {
            syncStatus = "Live sync unavailable: \(error.localizedDescription)"
            isUsingLiveBackend = false
        }
    }

    func addPantryItem(name: String, quantity: Double = 1, unit: String = "ct", location: PantryLocation = .pantry) {
        let normalized = IngredientNormalizer.normalize(name)
        let item = PantryItem(
            householdID: household.id,
            name: name,
            normalizedName: normalized,
            category: IngredientNormalizer.category(for: normalized),
            quantity: quantity,
            unit: unit,
            expirationDate: nil,
            location: location,
            notes: nil,
            lowStockThreshold: 1
        )
        pantryItems.insert(item, at: 0)
        persistPantryInsert(item)
    }

    func consume(_ item: PantryItem) {
        guard let index = pantryItems.firstIndex(of: item) else { return }
        pantryItems[index].quantity = max(0, pantryItems[index].quantity - 1)
        persistPantryQuantity(pantryItems[index])
    }

    func delete(_ item: PantryItem) {
        pantryItems.removeAll { $0.id == item.id }
        guard isUsingLiveBackend else { return }
        Task {
            do { try await supabase.deletePantryItem(itemID: item.id) }
            catch { syncStatus = "Could not delete pantry item: \(error.localizedDescription)" }
        }
    }

    func addRecipe(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
        guard isUsingLiveBackend else { return }
        Task {
            do {
                let saved = try await supabase.insertRecipe(recipe)
                if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                    recipes[index] = saved
                }
                syncStatus = "Recipe saved to Supabase"
            } catch {
                syncStatus = "Recipe saved locally only: \(error.localizedDescription)"
            }
        }
    }

    func addMeal(recipeID: EntityID, date: Date = Date().addingTimeInterval(86_400), mealType: MealType = .dinner) {
        guard let recipe = recipes.first(where: { $0.id == recipeID }) else { return }
        let plan = MealPlan(householdID: household.id, recipeID: recipe.id, plannedDate: date, mealType: mealType, servings: recipe.servings)
        mealPlans.append(plan)
        guard isUsingLiveBackend else { return }
        Task {
            do {
                let saved = try await supabase.insertMealPlan(plan)
                if let index = mealPlans.firstIndex(where: { $0.id == plan.id }) {
                    mealPlans[index] = saved
                }
                syncStatus = "Meal plan synced"
            } catch {
                syncStatus = "Meal plan saved locally only: \(error.localizedDescription)"
            }
        }
    }

    func regenerateShoppingList() {
        shoppingList = generatedShoppingList
    }

    func toggleShoppingItem(_ item: ShoppingListItem) {
        if shoppingList.isEmpty { shoppingList = generatedShoppingList }
        guard let index = shoppingList.firstIndex(where: { $0.id == item.id }) else { return }
        shoppingList[index].checked.toggle()
        let updated = shoppingList[index]
        guard isUsingLiveBackend else { return }
        Task {
            do { try await supabase.updateShoppingChecked(itemID: updated.id, checked: updated.checked) }
            catch { syncStatus = "Shopping item updated locally only: \(error.localizedDescription)" }
        }
    }

    func approveReceiptItems(_ items: [ParsedReceiptItem]) {
        items
            .filter(\.approved)
            .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.quantity > 0 }
            .forEach { item in
                let location: PantryLocation = ["dairy", "eggs", "produce"].contains(item.category) ? .fridge : .pantry
                addPantryItem(name: item.name.trimmingCharacters(in: .whitespacesAndNewlines), quantity: item.quantity, unit: item.unit, location: location)
            }
    }

    func signIn(email: String, password: String) async {
        do {
            _ = try await supabase.signIn(email: email, password: password)
            authMessage = "Signed in. Loading your household..."
            await refreshFromSupabase()
        } catch {
            authMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        do {
            _ = try await supabase.signUp(email: email, password: password)
            authMessage = "Account created. Loading your new household..."
            await refreshFromSupabase()
        } catch {
            authMessage = error.localizedDescription
        }
    }

    func signOut() {
        supabase.signOut()
        isUsingLiveBackend = false
        syncStatus = "Signed out. Using local starter data."
        authMessage = nil
    }

    private func apply(_ payload: SupabaseKitchenPayload) {
        household = payload.household
        pantryItems = payload.pantryItems
        recipes = payload.recipes
        mealPlans = payload.mealPlans
        shoppingList = payload.shoppingList
        stores = payload.stores
        saleItems = payload.saleItems
    }

    private func persistPantryInsert(_ item: PantryItem) {
        guard isUsingLiveBackend else { return }
        Task {
            do {
                let saved = try await supabase.insertPantryItem(item)
                if let index = pantryItems.firstIndex(where: { $0.id == item.id }) {
                    pantryItems[index] = saved
                }
                syncStatus = "Pantry synced"
            } catch {
                syncStatus = "Pantry item saved locally only: \(error.localizedDescription)"
            }
        }
    }

    private func persistPantryQuantity(_ item: PantryItem) {
        guard isUsingLiveBackend else { return }
        Task {
            do { try await supabase.updatePantryQuantity(itemID: item.id, quantity: item.quantity) }
            catch { syncStatus = "Quantity updated locally only: \(error.localizedDescription)" }
        }
    }
}
