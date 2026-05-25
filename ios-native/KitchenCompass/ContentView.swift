import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house") }

            PantryView()
                .tabItem { Label("Pantry", systemImage: "cabinet") }

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book.closed") }

            PlannerView()
                .tabItem { Label("Plan", systemImage: "calendar") }

            ShoppingView()
                .tabItem { Label("Shopping", systemImage: "cart") }

            ScanView()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(KitchenStore())
}
