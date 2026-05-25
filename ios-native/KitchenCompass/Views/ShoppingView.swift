import SwiftUI

struct ShoppingView: View {
    @EnvironmentObject private var store: KitchenStore

    var storeOptions: [StoreRecommendation] {
        SaleMatcher.recommendStores(items: store.activeShoppingList, sales: store.saleItems, stores: store.stores)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button("Regenerate from meal plan") { store.regenerateShoppingList() }
                        .buttonStyle(.borderedProminent)

                    SectionTitle(title: "Store guidance")
                    ForEach(storeOptions.prefix(2)) { option in
                        CompassCard {
                            Text(option.store.name).font(.headline)
                            Text(option.summary).foregroundStyle(Color.muted)
                            if option.store.preferred { CompassBadge(text: "preferred") }
                        }
                    }

                    SectionTitle(title: "List")
                    ForEach(store.activeShoppingList) { item in
                        ShoppingItemRow(item: item)
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Shopping")
        }
    }
}

struct ShoppingItemRow: View {
    @EnvironmentObject private var store: KitchenStore
    let item: ShoppingListItem

    var body: some View {
        CompassCard {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name).font(.headline).strikethrough(item.checked)
                    Text("\(item.quantityNeeded, specifier: "%g") \(item.unit) - \(item.category)")
                        .foregroundStyle(Color.muted)
                    if let storeID = item.recommendedStoreID, let recommended = store.stores.first(where: { $0.id == storeID }) {
                        Text("Recommended: \(recommended.name)").font(.caption).foregroundStyle(Color.basil)
                    }
                }
                Spacer()
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.checked ? Color.basil : Color.sage)
            }
        }
        .onTapGesture { store.toggleShoppingItem(item) }
    }
}
