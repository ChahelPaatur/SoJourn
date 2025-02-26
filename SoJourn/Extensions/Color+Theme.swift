import SwiftUI

extension Color {
    static let sojourn = SojournTheme()
    // static let accent = Color("AccentColor")
    // static let accentSecondary = Color("AccentSecondaryColor")
    // static let sojourYellow = Color("SojourYellow")
    
    // static var primaryText: Color { ... }
    // static var secondaryText: Color { ... }
    // static var cardBackground: Color { ... }
}

struct SojournTheme {
    let primary = Color.black
    let secondary = Color.gray
    let accent = Color.yellow
    let background = Color(.systemBackground)
    
    func adaptiveText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .white
    }
} 