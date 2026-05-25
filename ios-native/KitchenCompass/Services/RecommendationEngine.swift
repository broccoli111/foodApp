import Foundation

enum RecommendationEngine {
    static func score(pantry: [PantryItem], recipes: [Recipe], sales: [SaleItem], stores: [Store]) -> [RecipeRecommendation] {
        let pantryByName = Dictionary(uniqueKeysWithValues: pantry.filter { $0.quantity > 0 }.map { ($0.normalizedName, $0) })
        let expiringNames = Set(pantry.filter { item in
            guard let date = item.expirationDate else { return false }
            return Calendar.current.dateComponents([.day], from: Date(), to: date).day.map { $0 >= 0 && $0 <= 5 } ?? false
        }.map(\.normalizedName))

        var frequency: [String: Int] = [:]
        recipes.flatMap(\.ingredients).forEach { frequency[$0.normalizedName, default: 0] += 1 }

        return recipes.map { recipe in
            let required = recipe.ingredients.filter { !$0.optional }
            let used = required.compactMap { pantryByName[$0.normalizedName] }
            let missing = required.filter { pantryByName[$0.normalizedName] == nil }
            let saleMatches = missing.compactMap { ingredient in SaleMatcher.matches(for: ingredient.normalizedName, sales: sales, stores: stores).first }
            let expiringUsed = used.filter { expiringNames.contains($0.normalizedName) }
            let sharedBonus = required.reduce(0) { $0 + max(0, (frequency[$1.normalizedName] ?? 1) - 1) }
            let matchScore = required.isEmpty ? 0 : (Double(used.count) / Double(required.count)) * 55
            let score = Int((matchScore + Double(expiringUsed.count * 12) + Double(saleMatches.count * 7) + Double(sharedBonus * 2) - Double(missing.count * 9)).rounded())
            let percent = required.isEmpty ? 100 : Int((Double(used.count) / Double(required.count) * 100).rounded())
            let reasons = [
                used.isEmpty ? "Starts from a clear shopping list" : "Uses \(used.count) ingredient\(used.count == 1 ? "" : "s") already at home",
                missing.isEmpty ? "No missing required ingredients" : "Only \(missing.count) missing item\(missing.count == 1 ? "" : "s")",
                expiringUsed.isEmpty ? nil : "Uses \(expiringUsed.map(\.normalizedName).joined(separator: ", ")) before expiration",
                saleMatches.first.map { "\($0.saleItem.normalizedName) is on sale at \($0.store.name)" }
            ].compactMap { $0 }

            return RecipeRecommendation(
                recipeID: recipe.id,
                score: score,
                matchPercent: percent,
                pantryItemsUsed: used,
                missingItems: missing,
                saleMatches: saleMatches,
                reasons: reasons,
                badges: [missing.count <= 2 ? "minimal shopping" : nil, expiringUsed.isEmpty ? nil : "uses expiring", saleMatches.isEmpty ? nil : "sale opportunity"].compactMap { $0 }
            )
        }
        .sorted { $0.score > $1.score }
    }
}

enum SaleMatcher {
    static func matches(for normalizedName: String, sales: [SaleItem], stores: [Store]) -> [SaleMatch] {
        sales.compactMap { sale in
            guard let store = stores.first(where: { $0.id == sale.storeID }) else { return nil }
            let score = IngredientNormalizer.fuzzyMatch(normalizedName, sale.normalizedName)
            guard score >= 0.68 else { return nil }
            return SaleMatch(saleItem: sale, store: store, savingsScore: score * sale.confidence * (sale.salePrice == nil ? 0.8 : 1.1))
        }
        .sorted { $0.savingsScore > $1.savingsScore }
    }

    static func recommendStores(items: [ShoppingListItem], sales: [SaleItem], stores: [Store]) -> [StoreRecommendation] {
        stores.map { store in
            let storeSales = sales.filter { $0.storeID == store.id }
            let saleMatches = items.compactMap { SaleMatcher.matches(for: $0.normalizedName, sales: storeSales, stores: [store]).first }
            let covered = items.filter { item in saleMatches.contains { $0.saleItem.normalizedName == item.normalizedName } }
            let score = Double(covered.count * 8) + saleMatches.reduce(0) { $0 + $1.savingsScore * 5 } + (store.preferred ? 6 : 0) - (covered.count <= 1 && !store.preferred ? 7 : 0)
            return StoreRecommendation(store: store, coveredItems: covered, saleMatches: saleMatches, score: score, summary: "\(store.name) covers \(covered.count) of \(items.count) items with \(saleMatches.count) sale match\(saleMatches.count == 1 ? "" : "es").")
        }
        .sorted { $0.score > $1.score }
    }
}
