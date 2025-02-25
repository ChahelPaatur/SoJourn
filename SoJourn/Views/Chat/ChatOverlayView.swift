import SwiftUI

struct ChatOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text("Chat with AI Assistant")
                        .padding()
                }
                
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // Send message
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
} 