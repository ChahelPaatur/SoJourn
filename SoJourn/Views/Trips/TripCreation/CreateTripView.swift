import SwiftUI
import MapKit

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tripManager: TripManager
    @State private var currentStep = 0
    @State private var tripName = ""
    @State private var startDate = Date().addingTimeInterval(60*60*24*7)
    @State private var endDate = Date().addingTimeInterval(60*60*24*14)
    @State private var travelers = 2
    @State private var dietaryRestrictions = "None"
    @State private var transportationMode = "Flight"
    @State private var accommodation = "Hotel"
    @State private var budget = "$1000"
    @State private var weatherPreference = "Warm"
    @State private var showMap = false
    @State private var showingChatOverlay = false
    @State private var showingPublishPrompt = false
    @State private var itineraryExpanded = false
    @State private var itineraryHeight: CGFloat = 150
    @State private var position: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var chatHeight: CGFloat = 400
    @State private var dragOffset: CGFloat = 0
    
    // Dummy itinerary data
    let itineraryItems = [
        ItineraryItem(day: "Day 1", title: "Arrival & Check-in", description: "Arrive at destination and check into your hotel", time: "2:00 PM", cost: "$250"),
        ItineraryItem(day: "Day 1", title: "Welcome Dinner", description: "Enjoy local cuisine at a recommended restaurant", time: "7:00 PM", cost: "$80"),
        ItineraryItem(day: "Day 2", title: "City Tour", description: "Guided tour of major attractions", time: "9:00 AM", cost: "$45"),
        ItineraryItem(day: "Day 2", title: "Museum Visit", description: "Visit the national museum", time: "2:00 PM", cost: "$20"),
        ItineraryItem(day: "Day 3", title: "Beach Day", description: "Relax at the nearby beach", time: "10:00 AM", cost: "$15"),
        ItineraryItem(day: "Day 3", title: "Sunset Cruise", description: "Evening boat tour with dinner", time: "6:00 PM", cost: "$120"),
        ItineraryItem(day: "Day 4", title: "Shopping", description: "Visit local markets and shops", time: "11:00 AM", cost: "$100"),
        ItineraryItem(day: "Day 4", title: "Farewell Dinner", description: "Fine dining experience", time: "8:00 PM", cost: "$120"),
        ItineraryItem(day: "Day 5", title: "Checkout & Departure", description: "Check out and head to airport", time: "11:00 AM", cost: "$0")
    ]
    
    let transportationOptions = ["Car", "Uber", "Train", "Flight", "Cybertaxi"]
    let weatherOptions = ["Warm", "Cold", "Rainy", "Any"]
    let accommodationOptions = ["Hotel", "Airbnb", "Resort", "Hostel", "Camping"]
    let budgetOptions = ["$500", "$1000", "$2000", "$5000+"]
    let dietOptions = ["None", "Vegetarian", "Vegan", "Gluten-free", "Kosher", "Halal"]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.001) // Hack to capture taps outside of components
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if showingChatOverlay {
                        withAnimation(.spring()) {
                            showingChatOverlay = false
                        }
                    }
                }
            
            if showMap {
                mapView
            } else {
                quizView
            }
            
            // Top bar with dismiss button and search when map is shown
            VStack {
                HStack(spacing: 16) {
                    // Dismiss button (exists on both quiz and map)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .foregroundColor(.black)
                    }
                    
                    if showMap {
                        // Search bar (only on map)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search for places", text: $searchText)
                                .font(.system(size: 16))
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        
                        // Chat button (only on map)
                        Button {
                            withAnimation(.spring()) {
                                showingChatOverlay.toggle()
                            }
                        } label: {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16))
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .foregroundColor(.black)
                        }
                    } else {
                        Spacer() // Fill space on quiz screen
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .zIndex(2)
            
            // Chat Overlay
            if showMap && showingChatOverlay {
                chatOverlay
                    .zIndex(3)
            }
            
            // Bottom itinerary drawer (only on map)
            if showMap {
                itineraryDrawer
                    .zIndex(1)
            }
            
            // Publish Trip Name Prompt
            if showingPublishPrompt {
                publishPrompt
                    .zIndex(4)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    // Quiz view for gathering trip preferences
    private var quizView: some View {
        VStack {
            // Quiz content
            VStack(spacing: 30) {
                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<6) { step in
                        Circle()
                            .fill(step == currentStep ? Color.black : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Quiz question
                switch currentStep {
                case 0:
                    quizQuestionView(
                        icon: "calendar",
                        title: "When are you traveling?",
                        content: AnyView(
                            VStack {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.bottom, 20)
                                
                                DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                            }
                        )
                    )
                case 1:
                    quizQuestionView(
                        icon: "person.2.fill",
                        title: "Number of travelers",
                        content: AnyView(
                            Stepper("\(travelers) travelers", value: $travelers, in: 1...10)
                                .padding(.horizontal)
                        )
                    )
                case 2:
                    quizQuestionView(
                        icon: "fork.knife",
                        title: "Any dietary restrictions?",
                        content: AnyView(
                            OptionPickerView(selectedOption: $dietaryRestrictions, options: dietOptions)
                        )
                    )
                case 3:
                    quizQuestionView(
                        icon: "airplane",
                        title: "Preferred transportation",
                        content: AnyView(
                            OptionPickerView(selectedOption: $transportationMode, options: transportationOptions)
                        )
                    )
                case 4:
                    quizQuestionView(
                        icon: "house.fill",
                        title: "Preferred accommodation",
                        content: AnyView(
                            OptionPickerView(selectedOption: $accommodation, options: accommodationOptions)
                        )
                    )
                case 5:
                    quizQuestionView(
                        icon: "dollarsign.circle.fill",
                        title: "Budget range",
                        content: AnyView(
                            OptionPickerView(selectedOption: $budget, options: budgetOptions)
                        )
                    )
                default:
                    EmptyView()
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button {
                            withAnimation {
                                currentStep -= 1
                            }
                        } label: {
                            Text("Back")
                                .foregroundColor(.primary)
                                .frame(width: 120, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(25)
                        }
                    }
                    
                    Button {
                        if currentStep < 5 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            withAnimation {
                                showMap = true
                            }
                        }
                    } label: {
                        Text(currentStep < 5 ? "Next" : "Plan my trip")
                            .foregroundColor(.white)
                            .frame(width: currentStep > 0 ? 120 : 250, height: 50)
                            .background(Color.black)
                            .cornerRadius(25)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // Map view showing the trip plan
    private var mapView: some View {
        ZStack {
            Map(position: $position) {
                // Dummy pins
                Marker("Start", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                    .tint(.green)
                
                Marker("Hotel", coordinate: CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4167))
                    .tint(.blue)
                
                Marker("Restaurant", coordinate: CLLocationCoordinate2D(latitude: 37.7853, longitude: -122.4086))
                    .tint(.red)
                
                Marker("Museum", coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862))
                    .tint(.orange)
                
                Marker("Beach", coordinate: CLLocationCoordinate2D(latitude: 37.8025, longitude: -122.4382))
                    .tint(.purple)
                
                MapPolyline(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4167),
                    CLLocationCoordinate2D(latitude: 37.7853, longitude: -122.4086),
                    CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862),
                    CLLocationCoordinate2D(latitude: 37.8025, longitude: -122.4382)
                ])
                .stroke(.blue, lineWidth: 4)
            }
            .mapStyle(.standard(elevation: .realistic))
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    // Draggable itinerary drawer at the bottom
    private var itineraryDrawer: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                // Drag handle
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 4)
                    .cornerRadius(2)
                    .padding(.vertical, 8)
                
                // Itinerary content
                if itineraryExpanded {
                    VStack(spacing: 16) {
                        Text("Trip Itinerary")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(itineraryItems) { item in
                                    itineraryItemView(item)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                        
                        HStack(spacing: 20) {
                            Button {
                                // Navigate action (doesn't do anything yet)
                            } label: {
                                Text("Navigate")
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                            }
                            
                            Button {
                                withAnimation {
                                    showingPublishPrompt = true
                                }
                            } label: {
                                Text("Publish")
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .cornerRadius(25)
                            }
                        }
                        .padding([.horizontal, .bottom])
                    }
                } else {
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("5-Day Trip")
                                    .font(.headline)
                                
                                Text("$750 total • San Francisco")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Button {
                                    // Navigate action (doesn't do anything yet)
                                } label: {
                                    Text("Navigate")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .cornerRadius(20)
                                }
                                
                                Button {
                                    withAnimation {
                                        showingPublishPrompt = true
                                    }
                                } label: {
                                    Text("Publish")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.black)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 5)
            .frame(height: itineraryExpanded ? UIScreen.main.bounds.height * 0.7 : 120)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 && !itineraryExpanded {
                            withAnimation(.spring()) {
                                itineraryExpanded = true
                            }
                        } else if value.translation.height > 0 && itineraryExpanded {
                            withAnimation(.spring()) {
                                itineraryExpanded = false
                            }
                        }
                    }
            )
        }
    }

    // Chat overlay with AI assistant
    private var chatOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("AI Assistant")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Close button (closes only the chat)
                        Button {
                            withAnimation(.spring()) {
                                showingChatOverlay = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .padding(8)
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    // Drag handle
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 4)
                        .cornerRadius(2)
                        .padding(.vertical, 8)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newHeight = chatHeight - value.translation.height
                                    if newHeight >= 200 && newHeight <= 500 {
                                        chatHeight = newHeight
                                    }
                                }
                        )
                    
                    // Chat content
                    ScrollView {
                        VStack(spacing: 16) {
                            ChatBubble(text: "Hi! I'm your AI travel assistant. How can I help with your trip planning?", isUser: false)
                            
                            ChatBubble(text: "Can you suggest some activities in San Francisco?", isUser: true)
                            
                            ChatBubble(text: "I've added some popular attractions to your itinerary: Golden Gate Bridge, Alcatraz Island, Fisherman's Wharf, and Chinatown. Would you like more suggestions?", isUser: false)
                            
                            ChatBubble(text: "Find me a cheaper hotel option", isUser: true)
                            
                            ChatBubble(text: "I've found a budget-friendly hotel in Union Square for $150/night. Would you like me to update your itinerary?", isUser: false)
                        }
                        .padding()
                    }
                    
                    // Message input
                    HStack {
                        TextField("Type a message...", text: .constant(""))
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        
                        Button {
                            // Send message
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                }
                .frame(width: 320, height: chatHeight)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding()
            }
        }
    }
    
    // Publish prompt for naming the trip
    private var publishPrompt: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showingPublishPrompt = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("Name Your Trip")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Enter trip name", text: $tripName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                HStack(spacing: 20) {
                    Button {
                        withAnimation {
                            showingPublishPrompt = false
                        }
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.primary)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        publishTrip()
                    } label: {
                        Text("Save")
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .disabled(tripName.isEmpty)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    // Helper function for quiz question layout
    private func quizQuestionView(icon: String, title: String, content: AnyView) -> some View {
        VStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.black)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Helper function to create a trip and dismiss
    private func publishTrip() {
        let activities = itineraryItems.map { item in
            // Parse the time string to get a date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            let timeDate = dateFormatter.date(from: item.time) ?? Date()
            
            // Add this time to the start date
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            let day = Int(item.day.replacingOccurrences(of: "Day ", with: "")) ?? 1
            let adjustedDate = calendar.date(byAdding: .day, value: day - 1, to: startDate) ?? startDate
            
            let components = calendar.dateComponents([.hour, .minute], from: timeDate)
            let finalDate = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: adjustedDate) ?? adjustedDate
            
            return Activity(title: item.title, date: finalDate, notes: item.description)
        }
        
        let trip = Trip(
            title: tripName.isEmpty ? "My Trip" : tripName,
            destination: "San Francisco",
            startDate: startDate,
            endDate: endDate,
            notes: "Trip generated by AI assistant",
            status: .upcoming,
            isArchived: false,
            isDraft: false,
            isShared: false,
            activities: activities
        )
        
        tripManager.addTrip(trip)
        dismiss()
    }
    
    // Helper view to display an itinerary item
    private func itineraryItemView(_ item: ItineraryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.day)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(item.time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(item.cost)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Helper structs
struct ItineraryItem: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let description: String
    let time: String
    let cost: String
}

struct OptionPickerView: View {
    @Binding var selectedOption: String
    let options: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    selectedOption = option
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedOption == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOption == option ? Color.black.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
}

struct ChatBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(text)
                .padding(12)
                .background(isUser ? Color.black : Color.gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(18)
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

#Preview {
    CreateTripView()
        .environmentObject(TripManager.shared)
} 