import SwiftUI

struct RecipesView: View {
    @EnvironmentObject private var store: KitchenStore
    @State private var query = ""
    @State private var showingAddRecipe = false

    var filtered: [Recipe] {
        store.recipes.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Search recipes or tags", text: $query)
                        .textFieldStyle(.roundedBorder)
                    ForEach(filtered) { recipe in
                        NavigationLink { RecipeDetailView(recipe: recipe) } label: {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Recipes")
            .toolbar { Button("Add") { showingAddRecipe = true } }
            .sheet(isPresented: $showingAddRecipe) { AddRecipeView() }
        }
    }
}

struct RecipeCard: View {
    @EnvironmentObject private var store: KitchenStore
    let recipe: Recipe

    var matchPercent: Int {
        let pantryNames = Set(store.pantryItems.map(\.normalizedName))
        let required = recipe.ingredients.filter { !$0.optional }
        guard !required.isEmpty else { return 100 }
        let available = required.filter { pantryNames.contains($0.normalizedName) }.count
        return Int((Double(available) / Double(required.count) * 100).rounded())
    }

    var body: some View {
        CompassCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title).font(.headline)
                    Text(recipe.description).font(.subheadline).foregroundStyle(Color.muted)
                    FlowBadges(labels: Array(recipe.tags.prefix(3)))
                }
                Spacer()
                CompassBadge(text: "\(matchPercent)% match")
            }
        }
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject private var store: KitchenStore
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.description).foregroundStyle(Color.muted)
                if let sourceURL = recipe.sourceURL {
                    Link("Open source recipe", destination: sourceURL)
                        .font(.subheadline.weight(.semibold))
                }
                Button("Add to meal plan") { store.addMeal(recipeID: recipe.id) }.buttonStyle(.borderedProminent)
                SectionTitle(title: "Ingredients")
                CompassCard {
                    ForEach(recipe.ingredients) { ingredient in
                        Text("\(ingredient.quantity, specifier: "%g") \(ingredient.unit) \(ingredient.name)")
                    }
                }
                SectionTitle(title: "Instructions")
                CompassCard {
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                    }
                }
            }
            .padding()
        }
        .kitchenScreen()
        .navigationTitle(recipe.title)
    }
}

struct AddRecipeView: View {
    @EnvironmentObject private var store: KitchenStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = "Manually added household recipe."
    @State private var ingredients = "1 lb chicken breast\n1 bag spinach"
    @State private var instructions = "Cook until done."
    @State private var sourceURLText = ""
    @State private var importedRecipe: Recipe?
    @State private var importMessage: String?
    @State private var isImporting = false

    private let importService = RecipeImportService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Import from link") {
                    TextField("Recipe URL or Instagram Reel", text: $sourceURLText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Button(isImporting ? "Importing..." : "Import recipe from link") {
                        Task { await importFromLink() }
                    }
                    .disabled(isImporting || sourceURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("For recipe websites, Kitchen Compass looks for structured recipe data first. For Instagram/Reels, it imports from the post description/caption when available.")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                    if let importMessage {
                        Text(importMessage)
                            .font(.footnote)
                            .foregroundStyle(importMessage.localizedCaseInsensitiveContains("could") ? Color.clay : Color.basil)
                    }
                }

                Section("Review recipe") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Ingredients")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        TextEditor(text: $ingredients).frame(minHeight: 140)
                    }
                    VStack(alignment: .leading) {
                        Text("Instructions")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        TextEditor(text: $instructions).frame(minHeight: 140)
                    }
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func importFromLink() async {
        isImporting = true
        defer { isImporting = false }
        do {
            let recipe = try await importService.importRecipe(from: sourceURLText, householdID: store.household.id)
            importedRecipe = recipe
            title = recipe.title
            description = recipe.description
            ingredients = recipe.ingredients.map(\.rawText).joined(separator: "\n")
            instructions = recipe.instructions.joined(separator: "\n")
            importMessage = recipe.sourceURL?.host?.contains("instagram") == true
                ? "Imported from Instagram description. Review before saving."
                : "Imported recipe from URL. Review before saving."
        } catch {
            importMessage = error.localizedDescription
        }
    }

    private func saveRecipe() {
        let recipeID = UUID().uuidString
        let sourceURL = importedRecipe?.sourceURL ?? URL(string: sourceURLText.trimmingCharacters(in: .whitespacesAndNewlines))
        let sourceType: RecipeSourceType = sourceURL == nil ? .manual : .url
        let tags = importedRecipe?.tags ?? (sourceType == .url ? ["url", "imported"] : ["manual"])
        let recipe = Recipe(
            id: recipeID,
            householdID: store.household.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Household recipe." : description,
            imageURL: importedRecipe?.imageURL,
            sourceType: sourceType,
            sourceURL: sourceURL,
            servings: importedRecipe?.servings ?? 4,
            prepTimeMinutes: importedRecipe?.prepTimeMinutes ?? 10,
            cookTimeMinutes: importedRecipe?.cookTimeMinutes ?? 20,
            instructions: instructions.split(separator: "\n").map(String.init).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            tags: tags,
            favorite: false,
            ingredients: ingredients.split(separator: "\n").map { IngredientNormalizer.parseIngredientLine(String($0), recipeID: recipeID) }
        )
        store.addRecipe(recipe)
        dismiss()
    }
}
