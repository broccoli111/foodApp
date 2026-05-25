import Foundation

enum MockData {
    static func make() -> (pantry: [PantryItem], recipes: [Recipe], plans: [MealPlan], stores: [Store], sales: [SaleItem]) {
        let householdID = "household-demo"
        let now = Date()
        let soon = Calendar.current.date(byAdding: .day, value: 2, to: now)
        let chickenRecipeID = "recipe-chicken-spinach-pasta"
        let eggsRecipeID = "recipe-breakfast-eggs"
        let bowlsRecipeID = "recipe-rice-bean-bowls"
        let tacoRecipeID = "recipe-taco-night"

        let pantry = [
            PantryItem(householdID: householdID, name: "Baby spinach bag", normalizedName: "spinach", category: "produce", quantity: 1, unit: "bag", expirationDate: soon, location: .fridge, notes: "Opened", lowStockThreshold: 1),
            PantryItem(householdID: householdID, name: "Eggs", normalizedName: "eggs", category: "eggs", quantity: 8, unit: "ct", expirationDate: Calendar.current.date(byAdding: .day, value: 10, to: now), location: .fridge, notes: nil, lowStockThreshold: 6),
            PantryItem(householdID: householdID, name: "Chicken breasts", normalizedName: "chicken breast", category: "meat", quantity: 1.5, unit: "lb", expirationDate: Calendar.current.date(byAdding: .day, value: 4, to: now), location: .freezer, notes: nil, lowStockThreshold: 1),
            PantryItem(householdID: householdID, name: "Barilla penne", normalizedName: "penne pasta", category: "pasta", quantity: 1, unit: "box", expirationDate: nil, location: .pantry, notes: nil, lowStockThreshold: 1),
            PantryItem(householdID: householdID, name: "Black beans", normalizedName: "black beans", category: "canned", quantity: 2, unit: "can", expirationDate: nil, location: .pantry, notes: nil, lowStockThreshold: 1)
        ]

        func ingredient(_ recipeID: String, _ raw: String, _ name: String, _ quantity: Double, _ unit: String, _ category: String, optional: Bool = false) -> RecipeIngredient {
            RecipeIngredient(recipeID: recipeID, rawText: raw, name: name, normalizedName: name, quantity: quantity, unit: unit, category: category, optional: optional)
        }

        let recipes = [
            Recipe(id: chickenRecipeID, householdID: householdID, title: "Creamy Chicken Spinach Penne", description: "A cozy one-pan dinner that uses spinach before it wilts.", imageURL: nil, sourceType: .manual, sourceURL: nil, servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 25, instructions: ["Boil pasta.", "Cook chicken with garlic.", "Fold in spinach, milk, and cheese.", "Toss and serve."], tags: ["dinner", "family", "minimal shopping"], favorite: true, ingredients: [ingredient(chickenRecipeID, "1 box penne pasta", "penne pasta", 1, "box", "pasta"), ingredient(chickenRecipeID, "1 lb chicken breast", "chicken breast", 1, "lb", "meat"), ingredient(chickenRecipeID, "1 bag spinach", "spinach", 1, "bag", "produce"), ingredient(chickenRecipeID, "1 cup milk", "milk", 1, "cup", "dairy")]),
            Recipe(id: eggsRecipeID, householdID: householdID, title: "Spinach Egg Scramble", description: "Fast breakfast-for-dinner that clears out greens.", imageURL: nil, sourceType: .manual, sourceURL: nil, servings: 3, prepTimeMinutes: 5, cookTimeMinutes: 8, instructions: ["Whisk eggs.", "Wilt spinach.", "Scramble gently."], tags: ["quick", "uses expiring"], favorite: false, ingredients: [ingredient(eggsRecipeID, "6 eggs", "eggs", 6, "ct", "eggs"), ingredient(eggsRecipeID, "2 cups spinach", "spinach", 2, "cup", "produce")]),
            Recipe(id: bowlsRecipeID, householdID: householdID, title: "Black Bean Rice Bowls", description: "A flexible pantry meal with bright toppings.", imageURL: nil, sourceType: .manual, sourceURL: nil, servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 20, instructions: ["Cook rice.", "Warm beans.", "Top bowls family-style."], tags: ["vegetarian", "budget"], favorite: true, ingredients: [ingredient(bowlsRecipeID, "1 cup rice", "rice", 1, "cup", "grains"), ingredient(bowlsRecipeID, "2 cans black beans", "black beans", 2, "can", "canned"), ingredient(bowlsRecipeID, "1 cup salsa", "salsa", 1, "cup", "condiments")]),
            Recipe(id: tacoRecipeID, householdID: householdID, title: "Easy Chicken Taco Night", description: "Low-stress family dinner with sale-friendly ingredients.", imageURL: nil, sourceType: .manual, sourceURL: nil, servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 15, instructions: ["Season chicken.", "Warm shells.", "Set out toppings."], tags: ["kids", "sale opportunity"], favorite: false, ingredients: [ingredient(tacoRecipeID, "1 lb chicken breast", "chicken breast", 1, "lb", "meat"), ingredient(tacoRecipeID, "1 box taco shells", "taco shells", 1, "box", "grains"), ingredient(tacoRecipeID, "1 cup cheese", "cheese", 1, "cup", "dairy")])
        ]

        let stores = [
            Store(id: "store-costco", householdID: householdID, name: "Costco", chain: "Costco", preferred: true, zipCode: nil),
            Store(id: "store-bjs", householdID: householdID, name: "BJ's", chain: "BJ's", preferred: false, zipCode: nil),
            Store(id: "store-stop-shop", householdID: householdID, name: "Stop & Shop", chain: "Stop & Shop", preferred: true, zipCode: nil),
            Store(id: "store-shoprite", householdID: householdID, name: "ShopRite", chain: "ShopRite", preferred: true, zipCode: nil),
            Store(id: "store-whole-foods", householdID: householdID, name: "Whole Foods", chain: "Whole Foods", preferred: false, zipCode: nil),
            Store(id: "store-trader-joes", householdID: householdID, name: "Trader Joe's", chain: "Trader Joe's", preferred: true, zipCode: nil)
        ]

        let sales = [
            SaleItem(id: "sale-chicken-shoprite", storeID: "store-shoprite", householdID: householdID, itemName: "Boneless chicken breast", normalizedName: "chicken breast", category: "meat", salePrice: 2.99, saleDescription: "$2.99/lb family pack", startDate: now, endDate: Calendar.current.date(byAdding: .day, value: 7, to: now), source: .mock, confidence: 0.94),
            SaleItem(id: "sale-eggs-stopshop", storeID: "store-stop-shop", householdID: householdID, itemName: "Large eggs", normalizedName: "eggs", category: "eggs", salePrice: 2.49, saleDescription: "$2.49 dozen with card", startDate: now, endDate: Calendar.current.date(byAdding: .day, value: 5, to: now), source: .mock, confidence: 0.91),
            SaleItem(id: "sale-pasta-shoprite", storeID: "store-shoprite", householdID: householdID, itemName: "Barilla pasta", normalizedName: "penne pasta", category: "pasta", salePrice: 1.25, saleDescription: "4 for $5 assorted pasta", startDate: now, endDate: Calendar.current.date(byAdding: .day, value: 7, to: now), source: .mock, confidence: 0.88),
            SaleItem(id: "sale-milk-costco", storeID: "store-costco", householdID: householdID, itemName: "Milk 2 pack", normalizedName: "milk", category: "dairy", salePrice: 5.99, saleDescription: "Warehouse value on two gallons", startDate: now, endDate: Calendar.current.date(byAdding: .day, value: 10, to: now), source: .mock, confidence: 0.74)
        ]

        let plans = [MealPlan(householdID: householdID, recipeID: chickenRecipeID, plannedDate: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now, mealType: .dinner, servings: 4)]
        return (pantry, recipes, plans, stores, sales)
    }
}
