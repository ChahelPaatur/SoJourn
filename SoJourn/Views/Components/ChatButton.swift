import SwiftUI

struct ChatButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingChat: Bool
    
    var body: some View {
        Button(action: {
            showingChat = true
        }) {
            Image(systemName: "message")
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .frame(width: 56, height: 56)
                .background(colorScheme == .dark ? Color.yellow : Color.black)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4)
        }
        .padding(.trailing, 20)
    }
} 