import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var store: KitchenStore
    private let dates = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: "This week", subtitle: "Tap in meals now; drag and drop can be added later.")
                    ForEach(dates, id: \.self) { date in
                        CompassCard {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(date.formatted(.dateTime.weekday(.wide))).font(.headline)
                                    Text(date.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(Color.muted)
                                }
                                Spacer()
                                Button("Add pick") {
                                    if let top = store.recommendations.first { store.addMeal(recipeID: top.recipeID, date: date) }
                                }
                                .buttonStyle(.bordered)
                            }
                            ForEach(store.mealPlans.filter { Calendar.current.isDate($0.plannedDate, inSameDayAs: date) }) { plan in
                                if let recipe = store.recipes.first(where: { $0.id == plan.recipeID }) {
                                    Text("\(plan.mealType.rawValue.capitalized): \(recipe.title)")
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.cream)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Plan")
        }
    }
}
