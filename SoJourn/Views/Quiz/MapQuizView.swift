import SwiftUI

struct MapQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingAIChat = false
    
    var body: some View {
        ZStack {
            // Map content would go here
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            // Close button - top right
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.sojourYellow)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()
                
                // AI chat button - bottom right
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAIChat = true
                    }) {
                        Image(systemName: "text.bubble.fill")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.sojourYellow)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAIChat) {
            Text("AI Chat Interface")
                .padding()
        }
    }
}

#Preview {
    MapQuizView()
} 