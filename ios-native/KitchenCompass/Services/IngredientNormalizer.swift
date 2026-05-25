import Foundation

enum IngredientNormalizer {
    private static let brandWords: Set<String> = ["barilla", "trader", "joe", "joes", "kirkland", "costco", "shoprite"]
    private static let descriptors: Set<String> = ["fresh", "frozen", "organic", "baby", "bag", "box", "can", "jar", "pkg", "boneless", "skinless", "large", "small", "medium", "whole", "2%"]
    private static let aliases: [String: String] = [
        "chicken breasts": "chicken breast",
        "chicken breast": "chicken breast",
        "baby spinach": "spinach",
        "barilla penne": "penne pasta",
        "penne": "penne pasta",
        "penne pasta": "penne pasta",
        "2 dozen eggs": "eggs",
        "dozen eggs": "eggs",
        "egg": "eggs",
        "eggs": "eggs",
        "milk 2": "milk",
        "ground beef": "ground beef",
        "black beans": "black beans"
    ]

    static func normalize(_ input: String) -> String {
        let cleaned = input
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined(separator: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let alias = aliases[cleaned] { return alias }

        let tokens = cleaned
            .split(separator: " ")
            .map(String.init)
            .filter { Double($0) == nil }
            .filter { !brandWords.contains($0) && !descriptors.contains($0) }
            .map { token in
                switch token {
                case "breasts": return "breast"
                case "tomatoes": return "tomato"
                case "potatoes": return "potato"
                case "onions": return "onion"
                default: return token
                }
            }
        let phrase = tokens.joined(separator: " ")
        if let alias = aliases[phrase] { return alias }
        if phrase.contains("penne") { return "penne pasta" }
        if phrase.contains("spinach") { return "spinach" }
        if phrase.contains("egg") { return "eggs" }
        if phrase.contains("milk") { return "milk" }
        return phrase.isEmpty ? cleaned : phrase
    }

    static func category(for input: String) -> String {
        let normalized = normalize(input)
        let rules: [(String, [String])] = [
            ("produce", ["spinach", "lettuce", "tomato", "onion", "potato", "pepper", "cilantro", "avocado"]),
            ("meat", ["chicken", "beef", "pork", "turkey", "sausage"]),
            ("seafood", ["salmon", "shrimp", "tuna", "cod"]),
            ("dairy", ["milk", "cheese", "yogurt", "cream", "butter"]),
            ("eggs", ["egg"]),
            ("pasta", ["pasta", "penne", "spaghetti", "noodle"]),
            ("grains", ["rice", "quinoa", "oat", "bread", "tortilla"]),
            ("canned", ["beans", "broth", "corn"]),
            ("spices", ["salt", "pepper", "cumin", "paprika", "oregano"]),
            ("condiments", ["oil", "vinegar", "mustard", "salsa", "sauce"])
        ]
        return rules.first { _, words in words.contains { normalized.contains($0) } }?.0 ?? "other"
    }

    static func fuzzyMatch(_ lhs: String, _ rhs: String) -> Double {
        let left = normalize(lhs)
        let right = normalize(rhs)
        if left == right { return 1 }
        if left.contains(right) || right.contains(left) { return 0.82 }
        let leftTokens = Set(left.split(separator: " "))
        let rightTokens = Set(right.split(separator: " "))
        let intersection = leftTokens.intersection(rightTokens).count
        let union = leftTokens.union(rightTokens).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }

    static func parseIngredientLine(_ raw: String, recipeID: EntityID = "draft") -> RecipeIngredient {
        let parts = raw.split(separator: " ", maxSplits: 2).map(String.init)
        let quantity = Double(parts.first ?? "") ?? 1
        let unit = parts.count > 1 && Double(parts[0]) != nil ? parts[1] : "ct"
        let name = parts.count > 2 ? parts[2] : raw
        let normalized = normalize(name)
        return RecipeIngredient(
            recipeID: recipeID,
            rawText: raw,
            name: normalized,
            normalizedName: normalized,
            quantity: quantity,
            unit: unit,
            category: category(for: normalized),
            optional: raw.localizedCaseInsensitiveContains("optional")
        )
    }
}
