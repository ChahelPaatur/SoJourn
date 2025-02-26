import SwiftUI
import PhotosUI

struct TripAssistantView: View {
    @Environment(\.dismiss) private var dismiss
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
                Text("Trip Assistant")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
                .padding(.trailing)
            }
            .background(Color(.systemBackground))
            
            // Chat messages area with subtle background
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        AIChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            
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
            
            // Input area
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
                TextField("Ask anything about your trip...", text: $messageText)
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
            // Initial AI message
            if messages.isEmpty {
                let welcomeMessage = AIChatMessage(
                    id: UUID(),
                    text: "Hi there! I'm your AI travel assistant. How can I help with your trip planning?",
                    isFromUser: false,
                    image: nil
                )
                messages.append(welcomeMessage)
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil else {
            return
        }
        
        // Create user message
        let userMessage = AIChatMessage(
            id: UUID(),
            text: messageText,
            isFromUser: true,
            image: selectedImage
        )
        
        // Add to messages
        messages.append(userMessage)
        
        // Clear input
        let sentText = messageText
        messageText = ""
        selectedImage = nil
        
        // Simulate AI response (would connect to actual AI in production)
        generateAIResponse(to: sentText)
    }
    
    private func generateAIResponse(to text: String) {
        // Show typing indicator
        let typingMessage = AIChatMessage(
            id: UUID(),
            text: "Thinking...",
            isFromUser: false,
            image: nil,
            isSystemMessage: true
        )
        
        messages.append(typingMessage)
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Remove typing indicator
            if let lastIndex = messages.lastIndex(where: { $0.isSystemMessage }) {
                messages.remove(at: lastIndex)
            }
            
            // This would connect to your actual AI service
            let responseText = "I understand you're asking about \"\(text)\". I'm here to help plan your perfect journey!"
            let aiMessage = AIChatMessage(id: UUID(), text: responseText, isFromUser: false, image: nil)
            messages.append(aiMessage)
        }
    }
    
    // MARK: - Pinterest Integration
    
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
        
        // Simulate Pinterest API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Remove system message
            if let lastIndex = messages.lastIndex(where: { $0.isSystemMessage }) {
                messages.remove(at: lastIndex)
            }
            
            // Add AI response with Pinterest results
            let response = "I found some great ideas from your \"\(board)\" Pinterest board that would work well for your trip."
            let aiMessage = AIChatMessage(id: UUID(), text: response, isFromUser: false, image: nil)
            messages.append(aiMessage)
        }
    }
    
    // MARK: - Image Handling
    
    private func loadSelectedImage() {
        guard let selectedItem = selectedImageItem else { return }
        
        isProcessingImage = true
        
        selectedItem.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                self.isProcessingImage = false
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        self.selectedImage = uiImage
                    }
                case .failure:
                    // Handle error
                    print("Failed to load image")
                }
            }
        }
    }
} 