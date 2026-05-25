import Foundation

enum ShoppingListGenerator {
    static func generate(householdID: EntityID, plans: [MealPlan], recipes: [Recipe], pantry: [PantryItem], sales: [SaleItem], stores: [Store]) -> [ShoppingListItem] {
        let pantryByName = Dictionary(uniqueKeysWithValues: pantry.map { ($0.normalizedName, $0) })
        var needs: [String: RecipeIngredient] = [:]

        for plan in plans {
            guard let recipe = recipes.first(where: { $0.id == plan.recipeID }) else { continue }
            for ingredient in recipe.ingredients where !ingredient.optional {
                if var existing = needs[ingredient.normalizedName], existing.unit == ingredient.unit {
                    existing.quantity += ingredient.quantity
                    needs[ingredient.normalizedName] = existing
                } else if needs[ingredient.normalizedName] == nil {
                    needs[ingredient.normalizedName] = ingredient
                }
            }
        }

        return needs.values.compactMap { need in
            let remaining = max(0, need.quantity - (pantryByName[need.normalizedName]?.quantity ?? 0))
            guard remaining > 0 else { return nil }
            let bestSale = SaleMatcher.matches(for: need.normalizedName, sales: sales, stores: stores).first
            return ShoppingListItem(
                householdID: householdID,
                name: need.name,
                normalizedName: need.normalizedName,
                quantityNeeded: remaining,
                unit: need.unit,
                category: need.category,
                recommendedStoreID: bestSale?.store.id,
                matchedSaleItemID: bestSale?.saleItem.id,
                checked: false
            )
        }
        .sorted { $0.category < $1.category }
    }
}
