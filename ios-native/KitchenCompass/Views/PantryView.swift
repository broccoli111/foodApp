import SwiftUI

struct PantryView: View {
    @EnvironmentObject private var store: KitchenStore
    @State private var query = ""
    @State private var name = ""
    @State private var quantity = "1"
    @State private var unit = "ct"
    @State private var location: PantryLocation = .pantry

    var filteredItems: [PantryItem] {
        store.pantryItems.filter { item in
            query.isEmpty || item.name.localizedCaseInsensitiveContains(query) || item.normalizedName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: "Add item", subtitle: "Fast mobile pantry updates.")
                    CompassCard {
                        TextField("Item name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            TextField("Qty", text: $quantity).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                            TextField("Unit", text: $unit).textFieldStyle(.roundedBorder)
                        }
                        Picker("Location", selection: $location) {
                            ForEach(PantryLocation.allCases) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Button("Add to pantry") {
                            store.addPantryItem(name: name, quantity: Double(quantity) ?? 1, unit: unit, location: location)
                            name = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    SectionTitle(title: "Inventory")
                    TextField("Search pantry", text: $query)
                        .textFieldStyle(.roundedBorder)
                    ForEach(filteredItems) { item in
                        PantryItemCard(item: item)
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Pantry")
        }
    }
}

struct PantryItemCard: View {
    @EnvironmentObject private var store: KitchenStore
    let item: PantryItem

    var body: some View {
        CompassCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name).font(.headline)
                    Text("\(item.category.capitalized) in \(item.location.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(Color.muted)
                    if let threshold = item.lowStockThreshold, item.quantity <= threshold {
                        CompassBadge(text: "low stock", tone: .clay)
                    }
                }
                Spacer()
                Text("\(item.quantity, specifier: "%g") \(item.unit)").font(.headline)
            }
            HStack {
                Button("Mark used") { store.consume(item) }.buttonStyle(.bordered)
                Button("Delete", role: .destructive) { store.delete(item) }.buttonStyle(.bordered)
            }
        }
    }
}
