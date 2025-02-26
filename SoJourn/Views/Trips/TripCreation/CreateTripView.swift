import SwiftUI
import MapKit

struct CreateTripView: View {
    @Environment(\.colorScheme) private var colorScheme
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
    @State private var showingDismissOptions = false
    @State private var itineraryExpanded = false
    @State private var itineraryHeight: CGFloat = 150
    @State private var position: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var chatHeight: CGFloat = 400
    @State private var dragOffset: CGFloat = 0
    @State private var shouldDismissMap = false
    @State private var showingDraftNamePrompt = false
    @State private var draftName = ""
    
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
                        // Always show dismiss options regardless of which view we're in
                        showingDismissOptions = true
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
                        chatButton
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
            chatOverlay
            
            // Bottom itinerary drawer (only on map)
            if showMap {
                itineraryDrawer
                    .zIndex(1)
            }
            
            // ONLY show ONE dialog at a time with highest z-index
            if showingPublishPrompt {
                publishPrompt
                    .zIndex(10)
            } else if showingDismissOptions {
                dismissOptionsDialog
                    .zIndex(10)
            } else if showingDraftNamePrompt {
                draftNamePrompt
                    .zIndex(10)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    // Dismiss options dialog
    private var dismissOptionsDialog: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showingDismissOptions = false
                }
            
            VStack(spacing: 20) {
                Text("Exit Trip Creation")
                    .font(.headline)
                    .padding(.top)
                
                Text("Would you like to save your progress as a draft or discard this trip?")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Divider()
                
                Button {
                    // Show the draft name prompt instead of immediately saving and dismissing
                    saveAsDraft()
                    showingDismissOptions = false
                } label: {
                    Text("Save as Draft")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                
                Divider()
                
                Button {
                    showingDismissOptions = false
                    dismiss()
                } label: {
                    Text("Discard")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                
                Divider()
                
                Button {
                    showingDismissOptions = false
                } label: {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
            )
            .frame(width: 300)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
   
    // Quiz view for gathering trip preferences
    private var quizView: some View {
        VStack {
            // Quiz content
            VStack(spacing: 30) {
                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<6) { step in
                        Circle()
                            .fill(step == currentStep ? Color.black : Color.gray.opacity(0.6))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 40)
                
                // Title
                Text("Plan Your Trip")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                // Current question
                Group {
                    switch currentStep {
                    case 0:
                        quizQuestionView(
                            icon: "calendar",
                            title: "When are you traveling?",
                            content: AnyView(
                                VStack(spacing: 20) {
                                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .accentColor(Color(UIColor.label))
                                    
                                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .accentColor(Color(UIColor.label))
                                }
                            )
                        )
                    case 1:
                        quizQuestionView(
                            icon: "person.2.fill",
                            title: "How many travelers?",
                            content: AnyView(
                                Stepper(value: $travelers, in: 1...10) {
                                    Text("\(travelers) \(travelers == 1 ? "Person" : "People")")
                                        .font(.title3)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
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
                            icon: "car.fill",
                            title: "How will you travel?",
                            content: AnyView(
                                OptionPickerView(selectedOption: $transportationMode, options: transportationOptions)
                            )
                        )
                    case 4:
                        quizQuestionView(
                            icon: "house.fill",
                            title: "Where will you stay?",
                            content: AnyView(
                                OptionPickerView(selectedOption: $accommodation, options: accommodationOptions)
                            )
                        )
                    case 5:
                        quizQuestionView(
                            icon: "dollarsign.circle.fill",
                            title: "What's your budget?",
                            content: AnyView(
                                OptionPickerView(selectedOption: $budget, options: budgetOptions)
                            )
                        )
                    default:
                        quizQuestionView(
                            icon: "sun.max.fill",
                            title: "Weather preference?",
                            content: AnyView(
                                OptionPickerView(selectedOption: $weatherPreference, options: weatherOptions)
                            )
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale))
                
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
                                .padding()
                                .frame(width: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer()
                    
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
                        Text(currentStep < 5 ? "Next" : "Create Plan")
                            .padding()
                            .frame(width: 160)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // Map view with itinerary
    private var mapView: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                Marker("Starting Point", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                Marker("Destination", coordinate: CLLocationCoordinate2D(latitude: 37.8086, longitude: -122.4730))
                
                MapPolyline(
                    coordinates: [
                        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                        CLLocationCoordinate2D(latitude: 37.7850, longitude: -122.4350),
                        CLLocationCoordinate2D(latitude: 37.8000, longitude: -122.4450),
                        CLLocationCoordinate2D(latitude: 37.8086, longitude: -122.4730)
                    ],
                    contourStyle: .straight
                )
                .stroke(.black, lineWidth: 4)
            }
            .edgesIgnoringSafeArea(.all)
            
            // Itinerary panel at bottom - now with better styling
            VStack(spacing: 0) {
                // Drag indicator at the top of the card
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 5)
                    .cornerRadius(2.5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Summary when collapsed
                    if !itineraryExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trip to San Francisco")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text("5 days · $750 total")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            
                            HStack(spacing: 24) {
                                Button {
                                    // Navigate action
                                } label: {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("Navigate")
                                    }
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 3)
                                }
                                
                                Button {
                                    showingPublishPrompt = true
                                } label: {
                                    Text("Publish Trip")
                                        .frame(width: 120)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .shadow(radius: 3)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    } else {
                        // Full itinerary when expanded
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trip Itinerary")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("San Francisco, CA")
                                .font(.headline)
                                .foregroundColor(.black)
                                
                            Text("March 15 - March 20, 2025")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                            Text("Total Budget: $750")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                            
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(itineraryItems) { item in
                                        itineraryItemView(item)
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                            
                            HStack(spacing: 24) {
                                Button {
                                    // Navigate action
                                } label: {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("Navigate")
                                    }
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 3)
                                }
                                
                                Button {
                                    showingPublishPrompt = true
                                } label: {
                                    Text("Publish Trip")
                                        .frame(width: 120)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .shadow(radius: 3)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.2), radius: 6, y: -4)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    let threshold: CGFloat = 100
                    dragOffset = value.translation.height
                    
                    if abs(dragOffset) > threshold {
                        withAnimation(.spring()) {
                            itineraryExpanded.toggle()
                            dragOffset = 0
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
        
        // AI Chat Overlay - positioned lower
        .overlay(alignment: .bottom) {
            chatOverlay
        }
    }
    
    // Chat overlay
    @ViewBuilder
    private var chatOverlay: some View {
        if showingChatOverlay {
            // The overlay itself
            VStack {
                // Chat header
                HStack {
                    Text("Trip Assistant")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring()) {
                            showingChatOverlay = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Chat messages
                ScrollView {
                    VStack(spacing: 16) {
                        ChatBubble(text: "Hi there! I'm your AI travel assistant. How can I help with your trip planning?", isUser: false)
                        
                        ChatBubble(text: "I'd like to find some cheaper accommodation options near the city center.", isUser: true)
                        
                        ChatBubble(text: "I've found several budget-friendly options in downtown San Francisco, starting at $89 per night. Would you like me to recommend a few?", isUser: false)
                    }
                    .padding()
                }
                
                // Chat input
                HStack {
                    TextField("Ask anything about your trip...", text: .constant(""))
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    Button {
                        // Send message
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(UIColor.label))
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.2), radius: 6, y: -4)
            )
            // Use a ZStack with a transparent background to catch taps outside the chat
            .zIndex(100) // Ensure it's above other content
        }
    }
    
    // Bottom itinerary drawer
    private var itineraryDrawer: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Itinerary panel
            VStack(spacing: 0) {
                // Drag handle
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 5)
                    .cornerRadius(2.5)
                    .padding(.vertical, 8)
                
                if !itineraryExpanded {
                    // Collapsed view with trip summary
                    VStack(spacing: 16) {
                        // Summary info
                        VStack(spacing: 10) {
                            HStack {
                                Text("San Francisco Trip")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("$750")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("\(itineraryItems.count) activities")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("5 days")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Action buttons (now below itinerary)
                        HStack(spacing: 12) {
                            Button {
                                // Navigate action
                            } label: {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Navigate")
                                }
                                .frame(width: 120)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 3)
                            }
                            
                            Button {
                                showingPublishPrompt = true
                            } label: {
                                Text("Publish Trip")
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    .padding()
                } else {
                    // Expanded view with full itinerary
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Trip Itinerary")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("Total: $750")
                                .font(.headline)
                        }
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(itineraryItems) { item in
                                    itineraryItemView(item)
                                }
                            }
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                        
                        // Action buttons (consistent with collapsed view)
                        HStack(spacing: 20) {
                            // If the itinerary is expanded, add Spacer() before and after buttons for centering
                            if itineraryExpanded { Spacer() }
                            
                            Button {
                                // Navigate action
                            } label: {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Navigate")
                                }
                                .frame(width: 120)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 3)
                            }
                            
                            Button {
                                showingPublishPrompt = true
                            } label: {
                                Text("Publish Trip")
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 3)
                            }
                            
                            if itineraryExpanded { Spacer() }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, itineraryExpanded ? 30 : 16)
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height < -50 {
                            withAnimation(.spring()) {
                                itineraryExpanded = true
                            }
                        } else if value.translation.height > 50 {
                            withAnimation(.spring()) {
                                itineraryExpanded = false
                            }
                        }
                        dragOffset = 0
                    }
            )
        }
    }
    
    // Publish trip prompt
    private var publishPrompt: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showingPublishPrompt = false
                }
            
            VStack(spacing: 20) {
                Text("Name Your Trip")
                    .font(.headline)
                
                TextField("My Amazing Trip", text: $tripName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                HStack(spacing: 16) {
                    Button {
                        showingPublishPrompt = false
                    } label: {
                        Text("Cancel")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .cornerRadius(20)
                    }
                    
                    Button {
                        // Make sure this calls publishTrip directly
                        publishTrip()
                    } label: {
                        Text("Publish")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 10)
            )
            .padding(24)
        }
    }
    
    // Draft name prompt
    private var draftNamePrompt: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Don't dismiss on tap outside - user must choose an option
                }
            
            VStack(spacing: 20) {
                Text("Name Your Draft")
                    .font(.headline)
                    .padding(.top)
                
                Text("Give your draft trip a name so you can find it later.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                TextField("Trip Name", text: $draftName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Divider()
                
                Button {
                    // Save the draft with the provided name
                    saveDraftWithName()
                    showingDraftNamePrompt = false
                    dismiss()
                } label: {
                    Text("Save Draft")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                
                Divider()
                
                Button {
                    showingDraftNamePrompt = false
                } label: {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .frame(width: 300)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Helper Methods
    
    // Helper function for quiz question layout
    private func quizQuestionView(icon: String, title: String, content: AnyView) -> some View {
        VStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(Color(UIColor.label))
            
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
    
    // Save the trip as a draft
    private func saveAsDraft() {
        // Show the name prompt instead of immediately saving
        draftName = tripName.isEmpty ? "" : tripName
        showingDraftNamePrompt = true
    }
    
    // Helper function to create a trip and dismiss
    private func publishTrip() {
        print("Publishing trip: \(tripName)")
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
        
        print("Adding trip to tripManager")
        tripManager.addTrip(trip)
        dismiss()
    }
    
    // Add a helper method to save the draft with the entered name
    private func saveDraftWithName() {
        // Use the entered name if provided, otherwise use a default
        let name = draftName.isEmpty ? "Untitled Trip" : draftName
        
        // Create a new trip and mark as draft
        let newTrip = Trip(
            id: UUID(),
            title: name,
            destination: "San Francisco", // Using default destination
            startDate: startDate,
            endDate: endDate,
            notes: "Draft trip created on \(Date().formatted(date: .abbreviated, time: .shortened))",
            status: .upcoming,
            isArchived: false,
            isDraft: true,
            isShared: false,
            activities: [] // Empty activities list for draft
        )
        
        // Save to trip manager
        tripManager.addTrip(newTrip)
    }
    
    // Helper view to display an itinerary item
    private func itineraryItemView(_ item: ItineraryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.day)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(item.time)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(item.cost)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // Find the chat button and update it to match the X button style
    private var chatButton: some View {
        Button {
            if !showingChatOverlay {
                withAnimation(.spring()) {
                    showingChatOverlay = true
                }
            }
        } label: {
            Image(systemName: "message.fill")
                .font(.system(size: 16, weight: .bold))
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .foregroundColor(.black)
        }
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
    @Environment(\.colorScheme) private var colorScheme
    
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
                                .foregroundColor(colorScheme == .dark ? .yellow : .black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOption == option ? 
                                  (colorScheme == .dark ? Color.yellow.opacity(0.75) : Color.black.opacity(0.1)) 
                                  : Color.gray.opacity(0.1))
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