import SwiftUI

struct AccountButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink(destination: AccountSettingsView()) {
            Image(systemName: "person.circle")
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
} 