import Foundation

struct SupabaseConfiguration {
    let url: URL
    let publishableKey: String

    static func load() -> SupabaseConfiguration {
        if let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
           let values = NSDictionary(contentsOfFile: path),
           let urlString = values["SUPABASE_URL"] as? String,
           let url = URL(string: urlString) {
            return SupabaseConfiguration(url: url, publishableKey: values["SUPABASE_PUBLISHABLE_KEY"] as? String ?? "")
        }
        return SupabaseConfiguration(url: URL(string: "https://ohjezigyqrhkykbjimgo.supabase.co")!, publishableKey: "")
    }
}

enum SupabaseClientError: LocalizedError {
    case missingKey
    case missingSession
    case badURL
    case badResponse(status: Int, body: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Add SUPABASE_PUBLISHABLE_KEY to SupabaseConfig.plist before using live backend calls."
        case .missingSession:
            return "Sign in before syncing with Supabase."
        case .badURL:
            return "Could not build a Supabase request URL."
        case let .badResponse(status, body):
            return "Supabase returned HTTP \(status): \(body)"
        case .emptyResponse:
            return "Supabase returned an empty response."
        }
    }
}

final class SupabaseClient {
    private let configuration = SupabaseConfiguration.load()
    private let sessionKey = "KitchenCompass.SupabaseSession"
    private let userIDKey = "KitchenCompass.SupabaseUserID"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    var hasPublishableKey: Bool {
        !configuration.publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    var currentUserID: String? {
        UserDefaults.standard.string(forKey: userIDKey)
    }

    private var accessToken: String? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? decoder.decode(SupabaseAuthResponse.self, from: data) else { return nil }
        return session.accessToken
    }

    func signUp(email: String, password: String) async throws -> SupabaseAuthResponse {
        let response: SupabaseAuthResponse = try await auth(path: "/auth/v1/signup", body: ["email": email, "password": password])
        persist(response)
        return response
    }

    func signIn(email: String, password: String) async throws -> SupabaseAuthResponse {
        let response: SupabaseAuthResponse = try await auth(path: "/auth/v1/token?grant_type=password", body: ["email": email, "password": password])
        persist(response)
        return response
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.removeObject(forKey: userIDKey)
    }

    func loadKitchenData() async throws -> SupabaseKitchenPayload {
        guard let userID = currentUserID else { throw SupabaseClientError.missingSession }
        let profiles: [ProfileRow] = try await get("/rest/v1/profiles?select=*&id=eq.\(userID)&limit=1")
        guard let profile = profiles.first, let householdID = profile.defaultHouseholdID else {
            throw SupabaseClientError.emptyResponse
        }

        async let households: [HouseholdRow] = get("/rest/v1/households?select=*&id=eq.\(householdID)&limit=1")
        async let pantry: [PantryItemRow] = get("/rest/v1/pantry_items?select=*&household_id=eq.\(householdID)&order=updated_at.desc")
        async let recipes: [RecipeRow] = get("/rest/v1/recipes?select=*&household_id=eq.\(householdID)&order=updated_at.desc")
        async let ingredients: [RecipeIngredientRow] = get("/rest/v1/recipe_ingredients?select=*,recipes!inner(household_id)&recipes.household_id=eq.\(householdID)")
        async let plans: [MealPlanRow] = get("/rest/v1/meal_plans?select=*&household_id=eq.\(householdID)&order=planned_date.asc")
        async let shopping: [ShoppingListItemRow] = get("/rest/v1/shopping_list_items?select=*&household_id=eq.\(householdID)&order=created_at.asc")
        async let stores: [StoreRow] = get("/rest/v1/stores?select=*&household_id=eq.\(householdID)&order=name.asc")
        async let sales: [SaleItemRow] = get("/rest/v1/sale_items?select=*&household_id=eq.\(householdID)&order=created_at.desc")

        let householdRows = try await households
        let pantryRows = try await pantry
        let recipeRows = try await recipes
        let ingredientRows = try await ingredients
        let planRows = try await plans
        let shoppingRows = try await shopping
        let storeRows = try await stores
        let saleRows = try await sales

        return SupabaseKitchenPayload(
            household: householdRows.first?.model() ?? Household(id: householdID, name: "My Kitchen"),
            pantryItems: pantryRows.map { $0.model() },
            recipes: combine(recipeRows: recipeRows, ingredientRows: ingredientRows),
            mealPlans: planRows.map { $0.model() },
            shoppingList: shoppingRows.map { $0.model() },
            stores: storeRows.map { $0.model() },
            saleItems: saleRows.map { $0.model() }
        )
    }

    func insertPantryItem(_ item: PantryItem) async throws -> PantryItem {
        let insert = PantryItemInsert(
            householdID: item.householdID,
            name: item.name,
            normalizedName: item.normalizedName,
            category: item.category,
            quantity: item.quantity,
            unit: item.unit,
            expirationDate: item.expirationDate.map(Self.dateString),
            location: item.location.rawValue,
            notes: item.notes,
            lowStockThreshold: item.lowStockThreshold
        )
        let rows: [PantryItemRow] = try await post("/rest/v1/pantry_items", body: insert)
        return rows.first?.model() ?? item
    }

    func updatePantryQuantity(itemID: String, quantity: Double) async throws {
        let _: [PantryItemRow] = try await patch("/rest/v1/pantry_items?id=eq.\(itemID)", body: QuantityPatch(quantity: quantity))
    }

    func deletePantryItem(itemID: String) async throws {
        try await delete("/rest/v1/pantry_items?id=eq.\(itemID)")
    }

    func insertRecipe(_ recipe: Recipe) async throws -> Recipe {
        let insert = RecipeInsert(
            householdID: recipe.householdID,
            title: recipe.title,
            description: recipe.description,
            imageURL: recipe.imageURL?.absoluteString,
            sourceType: recipe.sourceType.rawValue,
            sourceURL: recipe.sourceURL?.absoluteString,
            servings: recipe.servings,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
            instructions: recipe.instructions,
            tags: recipe.tags,
            favorite: recipe.favorite
        )
        let recipeRows: [RecipeRow] = try await post("/rest/v1/recipes", body: insert)
        guard let savedRecipe = recipeRows.first else { throw SupabaseClientError.emptyResponse }
        let ingredientInserts = recipe.ingredients.map {
            RecipeIngredientInsert(recipeID: savedRecipe.id, rawText: $0.rawText, name: $0.name, normalizedName: $0.normalizedName, quantity: $0.quantity, unit: $0.unit, category: $0.category, optional: $0.optional)
        }
        let ingredientRows: [RecipeIngredientRow] = ingredientInserts.isEmpty ? [] : try await post("/rest/v1/recipe_ingredients", body: ingredientInserts)
        return recipeModel(row: savedRecipe, ingredients: ingredientRows)
    }

    func insertMealPlan(_ plan: MealPlan) async throws -> MealPlan {
        let insert = MealPlanInsert(householdID: plan.householdID, recipeID: plan.recipeID, plannedDate: Self.dateString(plan.plannedDate), mealType: plan.mealType.rawValue, servings: plan.servings)
        let rows: [MealPlanRow] = try await post("/rest/v1/meal_plans", body: insert)
        return rows.first?.model() ?? plan
    }

    func updateShoppingChecked(itemID: String, checked: Bool) async throws {
        let _: [ShoppingListItemRow] = try await patch("/rest/v1/shopping_list_items?id=eq.\(itemID)", body: CheckedPatch(checked: checked))
    }

    private func auth<T: Decodable>(path: String, body: [String: String]) async throws -> T {
        guard hasPublishableKey else { throw SupabaseClientError.missingKey }
        var request = try request(path: path, authenticated: false)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var request = try request(path: path, authenticated: true)
        request.httpMethod = "GET"
        return try await send(request)
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = try request(path: path, authenticated: true)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func patch<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = try request(path: path, authenticated: true)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func delete(_ path: String) async throws {
        var request = try request(path: path, authenticated: true)
        request.httpMethod = "DELETE"
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SupabaseClientError.badResponse(status: status, body: "")
        }
    }

    private func request(path: String, authenticated: Bool) throws -> URLRequest {
        guard hasPublishableKey else { throw SupabaseClientError.missingKey }
        guard let endpoint = URL(string: path, relativeTo: configuration.url)?.absoluteURL else { throw SupabaseClientError.badURL }
        var request = URLRequest(url: endpoint)
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let bearer = authenticated ? accessToken : nil
        request.setValue("Bearer \(bearer ?? configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupabaseClientError.badResponse(status: -1, body: "") }
        guard (200..<300).contains(http.statusCode) else {
            throw SupabaseClientError.badResponse(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        return try decoder.decode(T.self, from: data)
    }

    private func persist(_ response: SupabaseAuthResponse) {
        guard let data = try? encoder.encode(response) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
        if let userID = response.user?.id {
            UserDefaults.standard.set(userID, forKey: userIDKey)
        }
    }

    private func combine(recipeRows: [RecipeRow], ingredientRows: [RecipeIngredientRow]) -> [Recipe] {
        let ingredientsByRecipe = Dictionary(grouping: ingredientRows, by: \.recipeID)
        return recipeRows.map { recipeModel(row: $0, ingredients: ingredientsByRecipe[$0.id] ?? []) }
    }

    private func recipeModel(row: RecipeRow, ingredients: [RecipeIngredientRow]) -> Recipe {
        Recipe(
            id: row.id,
            householdID: row.householdID,
            title: row.title,
            description: row.description,
            imageURL: row.imageURL.flatMap(URL.init(string:)),
            sourceType: RecipeSourceType(rawValue: row.sourceType) ?? .manual,
            sourceURL: row.sourceURL.flatMap(URL.init(string:)),
            servings: row.servings,
            prepTimeMinutes: row.prepTimeMinutes,
            cookTimeMinutes: row.cookTimeMinutes,
            instructions: row.instructions,
            tags: row.tags,
            favorite: row.favorite,
            ingredients: ingredients.map { $0.model() }
        )
    }

    static func dateString(_ date: Date) -> String {
        PantryItemRow.dateFormatter.string(from: date)
    }
}

struct SupabaseKitchenPayload {
    let household: Household
    let pantryItems: [PantryItem]
    let recipes: [Recipe]
    let mealPlans: [MealPlan]
    let shoppingList: [ShoppingListItem]
    let stores: [Store]
    let saleItems: [SaleItem]
}
