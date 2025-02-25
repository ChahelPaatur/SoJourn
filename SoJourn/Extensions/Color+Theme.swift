import SwiftUI

extension Color {
    static let sojourn = SojournTheme()
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