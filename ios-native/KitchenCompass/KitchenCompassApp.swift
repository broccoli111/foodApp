import SwiftUI

@main
struct KitchenCompassApp: App {
    @StateObject private var store = KitchenStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(.basil)
        }
    }
}
