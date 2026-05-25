import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: KitchenStore

    var expiringSoon: [PantryItem] {
        store.pantryItems.filter { item in
            guard let date = item.expirationDate else { return false }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 99
            return days >= 0 && days <= 5
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kitchen Compass")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.muted)
                            .textCase(.uppercase)
                        Text("Cook from what you have.")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Color.ink)
                        Text("Buy what is missing where it makes sense.")
                            .font(.body)
                            .foregroundStyle(Color.muted)
                    }

                    HStack(spacing: 12) {
                        MetricCard(value: "\(store.pantryItems.count)", label: "items at home")
                        MetricCard(value: "\(expiringSoon.count)", label: "expiring soon", helper: "Use first")
                    }

                    SectionTitle(title: "Recommended this week")
                    ForEach(store.recommendations.prefix(3)) { recommendation in
                        if let recipe = store.recipes.first(where: { $0.id == recommendation.recipeID }) {
                            RecommendationRow(recipe: recipe, recommendation: recommendation)
                        }
                    }

                    SectionTitle(title: "Use soon")
                    ForEach(expiringSoon) { item in
                        CompassCard {
                            Text(item.name).font(.headline)
                            Text("Expires soon - plan it into a meal.")
                                .foregroundStyle(Color.muted)
                        }
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Home")
            .toolbar { NavigationLink("Settings") { SettingsView() } }
        }
    }
}

struct RecommendationRow: View {
    @EnvironmentObject private var store: KitchenStore
    let recipe: Recipe
    let recommendation: RecipeRecommendation

    var body: some View {
        CompassCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title).font(.headline)
                    Text(recommendation.reasons.joined(separator: ". "))
                        .font(.subheadline)
                        .foregroundStyle(Color.muted)
                    FlowBadges(labels: recommendation.badges)
                }
                Spacer()
                VStack {
                    Text("\(recommendation.matchPercent)%")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.basil)
                    Text("match").font(.caption).foregroundStyle(Color.muted)
                }
            }
            Button("Save to this week") { store.addMeal(recipeID: recipe.id) }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct FlowBadges: View {
    let labels: [String]
    var body: some View {
        HStack {
            ForEach(labels, id: \.self) { CompassBadge(text: $0, tone: $0.contains("sale") ? .clay : .sage, foreground: $0.contains("sale") ? .clay : .basil) }
        }
    }
}
