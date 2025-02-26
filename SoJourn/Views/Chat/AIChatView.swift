import SwiftUI
import PhotosUI

struct AIChatView: View {
    @State private var messageText = ""
    @State private var messages: [AIChatMessage] = []
    @State private var showingAttachmentOptions = false
    @State private var showingPinterestBoards = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessingImage = false
    
    // Sample Pinterest boards - replace with actual data from Pinterest API
    private let pinterestBoards = ["Travel Inspiration", "Destination Ideas", "Packing Tips", "Photography Spots", "Local Cuisine"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                    .padding()
                
                Spacer()
            }
            .background(Color(.systemBackground))
            
            // Chat messages area
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        AIChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            
            // Image preview (when an image is selected)
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
            
            // Pinterest board dropdown
            if showingPinterestBoards {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(pinterestBoards, id: \.self) { board in
                        Button {
                            searchPinterest(board: board)
                            showingPinterestBoards = false
                        } label: {
                            HStack {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.red)
                                Text(board)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                        }
                        
                        if board != pinterestBoards.last {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.horizontal)
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showingPinterestBoards)
            }
            
            // Input area with buttons
            HStack(alignment: .bottom, spacing: 8) {
                // Add attachment button (plus)
                Button {
                    showingAttachmentOptions = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
                .padding(.leading)
                
                // Pinterest search button
                Button {
                    withAnimation {
                        showingPinterestBoards.toggle()
                    }
                } label: {
                    Image(systemName: "p.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
                
                // Text input field
                TextField("Message AI assistant...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                // Send button
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
                .padding(.trailing)
                .disabled(messageText.isEmpty && selectedImage == nil)
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .top
            )
        }
        .sheet(isPresented: $showingAttachmentOptions) {
            AttachmentOptionsView(selectedImageItem: $selectedImageItem)
                .presentationDetents([.height(200)])
        }
        .onChange(of: selectedImageItem) { _, _ in
            loadSelectedImage()
        }
        .onAppear {
            // Welcome message
            if messages.isEmpty {
                let welcomeMessage = AIChatMessage(
                    id: UUID(),
                    text: "Hello! I'm your travel assistant. I can help plan your trip, suggest destinations, or answer travel questions. You can even upload images or search Pinterest for inspiration!",
                    isFromUser: false,
                    image: nil
                )
                messages.append(welcomeMessage)
            }
        }
    }
    
    private func loadSelectedImage() {
        Task {
            isProcessingImage = true
            if let data = try? await selectedImageItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    selectedImage = uiImage
                    isProcessingImage = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || selectedImage != nil else { return }
        
        // Create user message
        let userMessage = AIChatMessage(
            id: UUID(),
            text: messageText,
            isFromUser: true,
            image: selectedImage
        )
        messages.append(userMessage)
        
        // Reset input
        let sentText = messageText
        messageText = ""
        selectedImage = nil
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            simulateAIResponse(to: sentText)
        }
    }
    
    private func simulateAIResponse(to text: String) {
        // This would connect to your actual AI service
        let responseText = "I understand you're asking about \"\(text)\". I'm here to help plan your perfect journey!"
        let aiMessage = AIChatMessage(id: UUID(), text: responseText, isFromUser: false, image: nil)
        messages.append(aiMessage)
    }
    
    private func searchPinterest(board: String) {
        // Add a system message indicating Pinterest search
        let systemMessage = AIChatMessage(
            id: UUID(),
            text: "Searching Pinterest board: \(board)",
            isFromUser: false,
            image: nil,
            isSystemMessage: true
        )
        messages.append(systemMessage)
        
        // Here you would integrate with Pinterest API
        // For now, just simulate a response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = "I found some great ideas from your \"\(board)\" Pinterest board that would work well for your trip."
            let aiMessage = AIChatMessage(id: UUID(), text: response, isFromUser: false, image: nil)
            messages.append(aiMessage)
        }
    }
}

// AI Chat message model - renamed to avoid conflicts
struct AIChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let image: UIImage?
    var isSystemMessage: Bool = false
    var timestamp = Date()
}

// AI Chat bubble view - renamed to avoid conflicts
struct AIChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240)
                        .cornerRadius(12)
                }
                
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(12)
                        .background(
                            message.isSystemMessage ? Color.gray.opacity(0.2) :
                                (message.isFromUser ? Color.black : Color.blue.opacity(0.2))
                        )
                        .foregroundColor(message.isFromUser ? .white : .primary)
                        .cornerRadius(16)
                }
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
} 