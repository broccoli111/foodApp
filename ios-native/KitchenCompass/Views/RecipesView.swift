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
    @State private var ingredients = "1 lb chicken breast\n1 bag spinach"
    @State private var instructions = "Cook until done."

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $ingredients).frame(minHeight: 120)
                TextEditor(text: $instructions).frame(minHeight: 120)
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                Button("Save") {
                    let recipeID = UUID().uuidString
                    let recipe = Recipe(id: recipeID, householdID: store.household.id, title: title, description: "Manually added household recipe.", imageURL: nil, sourceType: .manual, sourceURL: nil, servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 20, instructions: instructions.split(separator: "\n").map(String.init), tags: ["manual"], favorite: false, ingredients: ingredients.split(separator: "\n").map { IngredientNormalizer.parseIngredientLine(String($0), recipeID: recipeID) })
                    store.addRecipe(recipe)
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}
