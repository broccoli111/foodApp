import Foundation

struct ImportedRecipeDraft {
    let title: String
    let description: String
    let ingredients: [String]
    let instructions: [String]
    let servings: Int
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let tags: [String]
    let sourceURL: URL
    let imageURL: URL?
    let sourceSummary: String
}

enum RecipeImportError: LocalizedError {
    case invalidURL
    case fetchFailed
    case noRecipeTextFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Enter a valid recipe URL."
        case .fetchFailed:
            return "Could not load that page. Some sites block app-based recipe importing."
        case .noRecipeTextFound:
            return "I could not find recipe text on that page. Try pasting the caption or recipe text manually."
        }
    }
}

final class RecipeImportService {
    func importRecipe(from urlString: String, householdID: EntityID) async throws -> Recipe {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme?.hasPrefix("http") == true else {
            throw RecipeImportError.invalidURL
        }

        let html = try await fetchHTML(from: url)
        let draft: ImportedRecipeDraft
        if isInstagramURL(url) {
            draft = try parseInstagram(html: html, url: url)
        } else if let structured = parseStructuredRecipe(html: html, url: url) {
            draft = structured
        } else {
            draft = try parseRecipeText(text: visibleText(from: html), titleFallback: title(from: html) ?? hostTitle(url), descriptionFallback: metaContent(html: html, key: "description") ?? metaContent(html: html, key: "og:description"), url: url, tag: "url")
        }

        let recipeID = UUID().uuidString
        let ingredients = draft.ingredients.map { IngredientNormalizer.parseIngredientLine($0, recipeID: recipeID) }
        return Recipe(
            id: recipeID,
            householdID: householdID,
            title: draft.title,
            description: draft.description,
            imageURL: draft.imageURL,
            sourceType: .url,
            sourceURL: draft.sourceURL,
            servings: draft.servings,
            prepTimeMinutes: draft.prepTimeMinutes,
            cookTimeMinutes: draft.cookTimeMinutes,
            instructions: draft.instructions,
            tags: draft.tags,
            favorite: false,
            ingredients: ingredients
        )
    }

    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 KitchenCompass/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode), let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw RecipeImportError.fetchFailed
        }
        return html
    }

    private func isInstagramURL(_ url: URL) -> Bool {
        (url.host ?? "").lowercased().contains("instagram.com")
    }

    private func parseInstagram(html: String, url: URL) throws -> ImportedRecipeDraft {
        let description = metaContent(html: html, key: "og:description") ?? metaContent(html: html, key: "description") ?? ""
        let caption = instagramCaption(from: decodeHTML(description))
        let text = caption.isEmpty ? visibleText(from: html) : caption
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw RecipeImportError.noRecipeTextFound }
        return try parseRecipeText(text: text, titleFallback: title(from: html) ?? "Instagram recipe", descriptionFallback: caption, url: url, tag: "instagram")
    }

    private func instagramCaption(from description: String) -> String {
        // Instagram metadata commonly looks like: "123 likes, 4 comments - user on May 1: \"caption\"".
        if let colon = description.range(of: ": ") {
            var caption = String(description[colon.upperBound...])
            caption = trimCaption(caption)
            return caption
        }
        return trimCaption(description)
    }

    private func trimCaption(_ text: String) -> String {
        var trimSet = CharacterSet.whitespacesAndNewlines
        trimSet.insert(charactersIn: "\"")
        return text.trimmingCharacters(in: trimSet)
    }

    private func parseStructuredRecipe(html: String, url: URL) -> ImportedRecipeDraft? {
        for json in jsonLDScripts(from: html) {
            guard let data = json.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) else { continue }
            if let recipe = findRecipeObject(in: object), let draft = draftFromStructured(recipe, url: url) {
                return draft
            }
        }
        return nil
    }

    private func jsonLDScripts(from html: String) -> [String] {
        regexMatches(#"<script[^>]+type=["']application/ld\+json["'][^>]*>(.*?)</script>"#, in: html, dotMatchesNewlines: true)
            .map { decodeHTML($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func findRecipeObject(in object: Any) -> [String: Any]? {
        if let dict = object as? [String: Any] {
            if isRecipeType(dict["@type"]) { return dict }
            if let graph = dict["@graph"] as? [Any] {
                for item in graph {
                    if let recipe = findRecipeObject(in: item) { return recipe }
                }
            }
        }
        if let array = object as? [Any] {
            for item in array {
                if let recipe = findRecipeObject(in: item) { return recipe }
            }
        }
        return nil
    }

    private func isRecipeType(_ value: Any?) -> Bool {
        if let string = value as? String { return string.localizedCaseInsensitiveContains("Recipe") }
        if let array = value as? [Any] { return array.contains { isRecipeType($0) } }
        return false
    }

    private func draftFromStructured(_ recipe: [String: Any], url: URL) -> ImportedRecipeDraft? {
        let title = stringValue(recipe["name"]) ?? hostTitle(url)
        let description = stringValue(recipe["description"]) ?? "Imported from an online recipe."
        let ingredients = (recipe["recipeIngredient"] as? [Any])?.compactMap { stringValue($0) } ?? []
        guard !ingredients.isEmpty else { return nil }
        let instructions = parseStructuredInstructions(recipe["recipeInstructions"])
        let tags = ["url"] + ((recipe["keywords"] as? String)?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [])
        return ImportedRecipeDraft(
            title: decodeHTML(title),
            description: decodeHTML(description),
            ingredients: ingredients.map(decodeHTML),
            instructions: instructions.isEmpty ? ["Review imported instructions before cooking."] : instructions.map(decodeHTML),
            servings: parseServings(recipe["recipeYield"]),
            prepTimeMinutes: parseISODurationMinutes(stringValue(recipe["prepTime"])),
            cookTimeMinutes: parseISODurationMinutes(stringValue(recipe["cookTime"])),
            tags: Array(Set(tags.filter { !$0.isEmpty })),
            sourceURL: url,
            imageURL: imageURL(from: recipe["image"]),
            sourceSummary: "Imported from structured recipe data"
        )
    }

    private func parseStructuredInstructions(_ value: Any?) -> [String] {
        if let string = value as? String { return splitInstructionText(string) }
        if let array = value as? [Any] {
            return array.flatMap { item -> [String] in
                if let string = item as? String { return splitInstructionText(string) }
                if let dict = item as? [String: Any] {
                    if let text = stringValue(dict["text"]) ?? stringValue(dict["name"]) { return [text] }
                    if let steps = dict["itemListElement"] { return parseStructuredInstructions(steps) }
                }
                return []
            }
        }
        return []
    }

    private func parseRecipeText(text: String, titleFallback: String, descriptionFallback: String?, url: URL, tag: String) throws -> ImportedRecipeDraft {
        let lines = text
            .components(separatedBy: .newlines)
            .map { decodeHTML($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { throw RecipeImportError.noRecipeTextFound }

        let title = firstTitleCandidate(in: lines) ?? titleFallback
        let ingredients = ingredientLines(from: lines)
        guard !ingredients.isEmpty else { throw RecipeImportError.noRecipeTextFound }
        let instructions = instructionLines(from: lines, excluding: Set(ingredients))
        return ImportedRecipeDraft(
            title: title,
            description: descriptionFallback?.isEmpty == false ? descriptionFallback! : "Imported from \(hostTitle(url)). Review before saving.",
            ingredients: ingredients,
            instructions: instructions.isEmpty ? ["Review the source link for full cooking instructions."] : instructions,
            servings: parseServings(from: lines) ?? 4,
            prepTimeMinutes: parseMinutes(label: "prep", from: lines) ?? 10,
            cookTimeMinutes: parseMinutes(label: "cook", from: lines) ?? 20,
            tags: [tag, "imported"],
            sourceURL: url,
            imageURL: nil,
            sourceSummary: tag == "instagram" ? "Imported from Instagram caption" : "Imported from page text"
        )
    }

    private func firstTitleCandidate(in lines: [String]) -> String? {
        lines.first { line in
            line.count <= 90 &&
            !line.contains("http") &&
            !line.hasPrefix("#") &&
            !measurementRegexMatches(line) &&
            !line.localizedCaseInsensitiveContains("ingredients") &&
            !line.localizedCaseInsensitiveContains("instructions")
        }
    }

    private func ingredientLines(from lines: [String]) -> [String] {
        var inIngredientSection = false
        var result: [String] = []
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("ingredient") {
                inIngredientSection = true
                continue
            }
            if lower.contains("instruction") || lower.contains("direction") || lower.contains("method") {
                inIngredientSection = false
            }
            if inIngredientSection || measurementRegexMatches(line) {
                if !line.localizedCaseInsensitiveContains("serves"), !line.localizedCaseInsensitiveContains("prep"), !line.localizedCaseInsensitiveContains("cook time") {
                    result.append(line.trimmingCharacters(in: CharacterSet(charactersIn: "--* ")))
                }
            }
        }
        return Array(result.prefix(30))
    }

    private func instructionLines(from lines: [String], excluding ingredients: Set<String>) -> [String] {
        var inInstructionSection = false
        var result: [String] = []
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("instruction") || lower.contains("direction") || lower.contains("method") {
                inInstructionSection = true
                continue
            }
            if inInstructionSection, !ingredients.contains(line), line.count > 12 {
                result.append(line.trimmingCharacters(in: CharacterSet(charactersIn: "--* ")))
            }
        }
        if result.isEmpty {
            result = lines.filter { $0.count > 30 && !ingredients.contains($0) && !measurementRegexMatches($0) }
        }
        return Array(result.prefix(20))
    }

    private func measurementRegexMatches(_ line: String) -> Bool {
        line.range(of: #"(^|\s)(\d+([./]\d+)?|one|two|three|four|five|six|seven|eight|nine|ten)\s*(cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|lb|lbs|pound|pounds|oz|ounce|ounces|g|gram|grams|kg|ml|l|can|cans|box|boxes|bag|bags|clove|cloves|slice|slices|dozen)\b"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func parseServings(from lines: [String]) -> Int? {
        for line in lines {
            if let match = firstCapture(#"serv(?:e|es|ings)?\s*:?\s*(\d+)"#, in: line) { return Int(match) }
        }
        return nil
    }

    private func parseServings(_ value: Any?) -> Int {
        if let int = value as? Int { return int }
        if let string = stringValue(value), let match = firstCapture(#"(\d+)"#, in: string) { return Int(match) ?? 4 }
        return 4
    }

    private func parseMinutes(label: String, from lines: [String]) -> Int? {
        for line in lines where line.localizedCaseInsensitiveContains(label) {
            if let match = firstCapture(#"(\d+)\s*(min|minute|minutes)"#, in: line) { return Int(match) }
        }
        return nil
    }

    private func parseISODurationMinutes(_ value: String?) -> Int {
        guard let value else { return 0 }
        var minutes = 0
        if let hours = firstCapture(#"(\d+)H"#, in: value) { minutes += (Int(hours) ?? 0) * 60 }
        if let mins = firstCapture(#"(\d+)M"#, in: value) { minutes += Int(mins) ?? 0 }
        return minutes
    }

    private func imageURL(from value: Any?) -> URL? {
        if let string = stringValue(value) { return URL(string: string) }
        if let array = value as? [Any] { return array.compactMap { imageURL(from: $0) }.first }
        if let dict = value as? [String: Any], let url = stringValue(dict["url"]) { return URL(string: url) }
        return nil
    }

    private func visibleText(from html: String) -> String {
        html
            .replacingOccurrences(of: #"<script[\s\S]*?</script>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"<style[\s\S]*?</style>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"</(p|div|li|h1|h2|h3|section|article|ol|ul)>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\n\s+"#, with: "\n", options: .regularExpression)
    }

    private func metaContent(html: String, key: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: key)
        let patterns = [
            #"<meta[^>]+(?:property|name)=["']\#(escaped)["'][^>]+content=["']([^"']*)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']*)["'][^>]+(?:property|name)=["']\#(escaped)["'][^>]*>"#
        ]
        for pattern in patterns {
            if let match = regexMatches(pattern, in: html, dotMatchesNewlines: false).first { return decodeHTML(match) }
        }
        return nil
    }

    private func title(from html: String) -> String? {
        metaContent(html: html, key: "og:title") ?? regexMatches(#"<title[^>]*>(.*?)</title>"#, in: html, dotMatchesNewlines: true).first.map(decodeHTML)
    }

    private func hostTitle(_ url: URL) -> String {
        (url.host ?? "Online recipe").replacingOccurrences(of: "www.", with: "")
    }

    private func splitInstructionText(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: "\n."))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 8 }
    }

    private func stringValue(_ value: Any?) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private func firstCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1, let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[swiftRange])
    }

    private func regexMatches(_ pattern: String, in text: String, dotMatchesNewlines: Bool) -> [String] {
        var options: NSRegularExpression.Options = [.caseInsensitive]
        if dotMatchesNewlines { options.insert(.dotMatchesLineSeparators) }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    private func decodeHTML(_ text: String) -> String {
        var result = text
        let entities = ["&amp;": "&", "&quot;": "\"", "&#34;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " "]
        for (entity, value) in entities { result = result.replacingOccurrences(of: entity, with: value) }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
