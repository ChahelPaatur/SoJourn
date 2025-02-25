import SwiftUI

struct FloatingActionButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showNewTripSheet: Bool
    
    var body: some View {
        Button(action: {
            showNewTripSheet = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .frame(width: 56, height: 56)
                .background(colorScheme == .dark ? Color.yellow : Color.black)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 80) // Adjust for tab bar height
    }
} 