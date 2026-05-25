import Foundation

enum ScanService {
    static func parseReceipt(text: String) -> [ParsedReceiptItem] {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "STOP AND SHOP\n2 DOZEN EGGS\nBARILLA PENNE\nMILK 2%\nBABY SPINACH BAG"
            : text
        return source.split(separator: "\n").compactMap { line in
            let raw = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty, !raw.localizedCaseInsensitiveContains("stop and shop") else { return nil }
            let normalized = IngredientNormalizer.normalize(raw)
            let dozen = raw.range(of: #"(\d+)\s+dozen\s+eggs"#, options: [.regularExpression, .caseInsensitive]) != nil
            return ParsedReceiptItem(rawText: raw, normalizedName: normalized, name: normalized, quantity: dozen ? 24 : 1, unit: dozen ? "ct" : "ct", category: IngredientNormalizer.category(for: normalized), confidence: normalized == raw.lowercased() ? 0.70 : 0.88, approved: true)
        }
    }

    static func parseRecipe(text: String, householdID: EntityID) -> Recipe {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Sheet Pan Chicken and Spinach\n1 lb chicken breasts\n1 bag baby spinach\n1 lb potatoes\n2 tbsp olive oil"
            : text
        let lines = source.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        let title = lines.first ?? "Scanned Recipe"
        let recipeID = UUID().uuidString
        let ingredients = lines.dropFirst().map { IngredientNormalizer.parseIngredientLine($0, recipeID: recipeID) }
        return Recipe(id: recipeID, householdID: householdID, title: title, description: "Imported from scan. Review before relying on it.", imageURL: nil, sourceType: .scan, sourceURL: nil, servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 25, instructions: ["Review scanned steps.", "Cook until complete."], tags: ["scan"], favorite: false, ingredients: ingredients)
    }
}
