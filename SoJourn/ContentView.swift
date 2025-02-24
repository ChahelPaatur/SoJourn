//
//  ContentView.swift
//  SoJourn
//
//  Created by Chahel Paatur on 2/23/25.
//

import SwiftUI

// First, create a Trip model to manage the data
struct Trip: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    var isArchived: Bool
    var isDraft: Bool
}

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var selectedTab = 0
    @State private var showNewTripSheet = false
    @State private var showingAccountSheet = false
    @State private var selectedFilter = "Upcoming"
    let filters = ["Upcoming", "Archived", "Drafts"]
    @State private var trips: [Trip] = [
        Trip(title: "Thailand 2025 Da Boys", date: "June 21 • 7 Days", isArchived: false, isDraft: false),
        Trip(title: "Disney Party", date: "July 15 • 3 Days", isArchived: false, isDraft: false),
        Trip(title: "Paris 2024", date: "Completed • 5 Days", isArchived: true, isDraft: false),
        Trip(title: "London Trip", date: "Completed • 4 Days", isArchived: true, isDraft: false),
        Trip(title: "Japan 2025", date: "Draft • Last edited 2 days ago", isArchived: false, isDraft: true),
        Trip(title: "Mexico Trip", date: "Draft • Last edited 1 week ago", isArchived: false, isDraft: true)
    ]
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                LandingView()
                    .environmentObject(authManager)
            } else if authManager.isNewUser && !authManager.hasCompletedQuiz {
                PreferenceQuizView()
                    .environmentObject(authManager)
            } else {
                mainTabView
            }
        }
        .preferredColorScheme(authManager.userProfile.darkModeEnabled ? .dark : .light)
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                TripsView(
                    selectedFilter: $selectedFilter,
                    filters: filters,
                    trips: $trips,
                    showNewTripSheet: $showNewTripSheet,
                    showingAccountSheet: $showingAccountSheet,
                    selectedTab: $selectedTab
                )
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                Text("Trips")
            }
            .tag(0)
            
            NavigationView {
                AccountView(showingAccountSheet: $showingAccountSheet, onSignOut: {
                    authManager.isAuthenticated = false
                    authManager.isNewUser = true
                    authManager.hasCompletedQuiz = false
                })
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "person.fill" : "person")
                Text("Account")
            }
            .tag(1)
        }
    }
    
    func archiveTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].isArchived = true
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll(where: { $0.id == trip.id })
    }
}

// Move TripsView to a separate file
struct TripsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var selectedFilter: String
    let filters: [String]
    @Binding var trips: [Trip]
    @Binding var showNewTripSheet: Bool
    @Binding var showingAccountSheet: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            FilterPillsView(selectedFilter: $selectedFilter, filters: filters)
            
            TripListView(
                selectedFilter: selectedFilter,
                trips: $trips,
                onArchive: archiveTrip,
                onDelete: deleteTrip
            )
        }
        .navigationTitle("Your Trips")
        .navigationBarItems(trailing: accountButton)
        .overlay(newTripButton)
    }
    
    private var accountButton: some View {
        Button(action: { showingAccountSheet = true }) {
            Image(systemName: "person.circle")
                .foregroundColor(authManager.userProfile.darkModeEnabled ? .white : .black)
        }
    }
    
    private var newTripButton: some View {
        Group {
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    Button(action: { showNewTripSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .frame(width: 56, height: 56)
                            .foregroundColor(authManager.userProfile.darkModeEnabled ? .black : .white)
                            .background(authManager.userProfile.darkModeEnabled ? Color.yellow : Color.black)
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 64)
                    .sheet(isPresented: $showNewTripSheet) {
                        NewTripView()
                            .environmentObject(authManager)
                    }
                }
            }
        }
    }
    
    func archiveTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].isArchived = true
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll(where: { $0.id == trip.id })
    }
}

// Placeholder Views
struct YourTripsView: View {
    var body: some View {
        Text("Your Trips")
    }
}

struct SharedTripsView: View {
    var body: some View {
        Text("Shared Trips")
    }
}

struct DiscoverView: View {
    var body: some View {
        Text("Discover")
    }
}

struct PastTripsView: View {
    var body: some View {
        Text("Past Trips")
    }
}

struct NewTripPlanningView: View {
    var body: some View {
        Text("New Trip Planning")
    }
}

// Update TripCard to handle different states
struct TripCard: View {
    @EnvironmentObject var authManager: AuthenticationManager
    let title: String
    let date: String
    @State private var showingOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(authManager.userProfile.darkModeEnabled ? .white : .black)
                    
                    Text(date)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    Button(action: {
                        // Archive action
                    }) {
                        Label("Archive", systemImage: "archivebox")
                    }
                    
                    Button(action: {
                        // Edit action
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // Share action
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(authManager.userProfile.darkModeEnabled ? .white : .black)
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
        .background(authManager.userProfile.darkModeEnabled ? Color.black.opacity(0.2) : .white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Update SwipeableCard to handle actions
struct SwipeableCard: View {
    let trip: Trip
    let onArchive: (Trip) -> Void
    let onDelete: (Trip) -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showingDeleteAlert = false
    @GestureState private var isDragging = false
    let haptics = UIImpactFeedbackGenerator(style: .medium)
    let notificationHaptics = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        notificationHaptics.notificationOccurred(.success)
                        offset = 0
                        onArchive(trip)
                    }
                }) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 16))
                        .frame(width: 50, height: 60)
                        .background(Color.orange)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    notificationHaptics.notificationOccurred(.warning)
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .frame(width: 50, height: 60)
                        .background(Color.red)
                        .foregroundColor(.white)
                }
            }
            .opacity(min(-offset / 50, 1.0))
            
            // Card content
            TripCard(title: trip.title, date: trip.date)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .updating($isDragging) { value, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            let translation = value.translation.width
                            offset = translation > 0 ? log(translation + 1) : translation
                            
                            if translation < -30 && !isDragging {
                                haptics.prepare()
                                haptics.impactOccurred()
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if translation < -50 {
                                    offset = -100
                                    haptics.impactOccurred()
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
                .alert("Delete Trip", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                    Button("Delete", role: .destructive) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = -UIScreen.main.bounds.width
                            notificationHaptics.notificationOccurred(.success)
                            onDelete(trip)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this trip? This action cannot be undone.")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}

