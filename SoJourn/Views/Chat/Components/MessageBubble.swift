import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromUser ? 
                          (colorScheme == .dark ? Color.yellow : Color.black) :
                          Color(.systemGray5))
                .foregroundColor(message.isFromUser ?
                               (colorScheme == .dark ? .black : .white) :
                               .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 1)
            
            if !message.isFromUser { Spacer() }
        }
    }
} 