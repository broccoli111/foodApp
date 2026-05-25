import SwiftUI

extension Color {
    static let cream = Color(red: 1.0, green: 0.973, blue: 0.933)
    static let oat = Color(red: 0.961, green: 0.914, blue: 0.843)
    static let sage = Color(red: 0.553, green: 0.667, blue: 0.569)
    static let basil = Color(red: 0.247, green: 0.435, blue: 0.310)
    static let clay = Color(red: 0.851, green: 0.529, blue: 0.373)
    static let ink = Color(red: 0.137, green: 0.188, blue: 0.165)
    static let muted = Color(red: 0.447, green: 0.502, blue: 0.475)
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cream.ignoresSafeArea())
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func kitchenScreen() -> some View {
        modifier(ScreenBackground())
    }
}
