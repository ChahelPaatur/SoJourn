import SwiftUI
import MapKit

struct TripMapView: View {
    @Binding var tripName: String
    @Binding var showingNamePrompt: Bool
    @Binding var showingDiscardAlert: Bool
    let onPublish: () -> Void
    let onDismiss: () -> Void
    @State private var showingChat = false
    @State private var searchText = ""
    @State private var bottomSheetPosition: BottomSheetPosition = .collapsed
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    enum BottomSheetPosition {
        case collapsed
        case expanded
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map {
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            HStack(spacing: 16) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                SearchBar(text: $searchText)
                    .frame(maxWidth: 240)
                
                Button(action: { showingChat.toggle() }) {
                    Image(systemName: "message")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            VStack {
                Spacer()
                
                BottomSheetView(position: $bottomSheetPosition) {
                    VStack(spacing: 16) {
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 4)
                        
                        if bottomSheetPosition == .collapsed {
                            CollapsedItineraryView()
                        } else {
                            ExpandedItineraryView()
                        }
                        
                        HStack {
                            Button("Navigate") {
                                // Navigation logic
                            }
                            .buttonStyle(RoundedButtonStyle(filled: false))
                            
                            Button("Publish") {
                                onPublish()
                            }
                            .buttonStyle(RoundedButtonStyle(filled: true))
                        }
                        .padding(.bottom)
                    }
                    .padding(.top)
                }
            }
            
            if showingChat {
                ChatOverlay(isPresented: $showingChat)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 15))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct BottomSheetView<Content: View>: View {
    @Binding var position: TripMapView.BottomSheetPosition
    let content: Content
    @GestureState private var translation: CGFloat = 0
    
    private let minHeight: CGFloat = 180
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    
    init(position: Binding<TripMapView.BottomSheetPosition>, @ViewBuilder content: () -> Content) {
        self._position = position
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .frame(height: position == .collapsed ? minHeight : maxHeight)
            .overlay(alignment: .topTrailing) {
                if position == .expanded {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            position = .collapsed
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.height > threshold {
                                position = .collapsed
                            } else if value.translation.height < -threshold {
                                position = .expanded
                            } else {
                                position = position
                            }
                        }
                    }
            )
    }
}

struct CollapsedItineraryView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Day 1 • June 21")
                        .font(.headline)
                    Text("3 Activities")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("$250")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            Divider()
            
            Text("Swipe up for full itinerary")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ExpandedItineraryView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trip Itinerary")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                
                ForEach(1...3, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day \(day) • June \(20 + day)")
                            .font(.headline)
                        
                        ForEach(1...3, id: \.self) { activity in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Activity \(activity)")
                                        .font(.subheadline)
                                        .bold()
                                    Text("2 hours • 10:00 AM")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("$80")
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if day != 3 {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct ChatOverlay: View {
    @Binding var isPresented: Bool
    @State private var message = ""
    @State private var messages: [(String, Bool)] = []
    
    let predefinedResponses = [
        "hello": "Hi there! How can I help with your trip planning?",
        "hi": "Hello! Need help adjusting your itinerary?",
        "help": "I can help you with:\n• Adjusting your budget\n• Finding activities\n• Modifying the schedule\n• Finding restaurants\nWhat would you like to know?",
        "thanks": "You're welcome! Let me know if you need anything else.",
        "thank you": "You're welcome! Feel free to ask more questions."
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages.indices, id: \.self) { index in
                        ChatBubble(message: messages[index].0, isUser: messages[index].1)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Message", text: $message)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }
    
    private func sendMessage() {
        guard !message.isEmpty else { return }
        let userMessage = message
        messages.append((userMessage, true))
        
        let lowercasedMessage = userMessage.lowercased()
        let response = predefinedResponses[lowercasedMessage] ?? "I understand. Let me help you optimize your trip based on that."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            messages.append((response, false))
        }
        
        message = ""
    }
}

struct ChatBubble: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(message)
                .padding(12)
                .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .primary)
                .clipShape(CustomCorner(
                    radius: 16,
                    corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
                ))
            
            if !isUser { Spacer() }
        }
    }
}

struct CustomCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 