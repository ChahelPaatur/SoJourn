//
//  ContentView.swift
//  SoJourn
//
//  Created by Chahel Paatur on 2/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var tripManager = TripManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0
    @State private var showingNewTripSheet = false
    @State private var selectedTrip: Trip?
    @State private var showingEditView = false
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                LandingView()
            } else if authManager.showWelcomeScreen {
                GetStartedView()
            } else {
                mainView
            }
        }
        .environmentObject(tripManager)
        .environmentObject(authManager)
        .onReceive(tripManager.$isEditingTrip) { isEditing in
            if isEditing, let tripId = tripManager.tripToEdit {
                self.selectedTrip = tripManager.trips.first(where: { $0.id == tripId })
                self.showingEditView = true
            }
        }
        .sheet(isPresented: $showingEditView, onDismiss: {
            tripManager.isEditingTrip = false
            tripManager.tripToEdit = nil
        }) {
            if let trip = selectedTrip {
                EditTripView(trip: trip)
            }
        }
    }
    
    private var mainView: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TripsHomeView()
                    .tabItem {
                        Label("Trips", systemImage: "airplane.departure")
                    }
                    .tag(0)
                
                SharedTripsView()
                    .tabItem {
                        Label("Shared", systemImage: "person.2.fill")
                    }
                    .tag(1)
                
                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "safari.fill")
                    }
                    .tag(2)
                
                CompletedTripsView()
                    .tabItem {
                        Label("Past", systemImage: "photo.stack.fill")
                    }
                    .tag(3)
                
                ProfileView()
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            .accentColor(.accent)
            .onAppear {
                // Set the inactive tab color
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                
                // Set background color
                appearance.backgroundColor = UIColor.systemBackground
                
                // Set inactive tab color
                let inactiveColor = UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? 
                        UIColor.systemGray3 : UIColor.systemGray
                }
                
                appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
                
                // Set active tab color - Pinterest-inspired accent in dark mode, deeper accent in light mode
                let activeColor = UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? 
                        UIColor(Color.sojourYellow) : UIColor(Color.accent)
                }
                
                appearance.stackedLayoutAppearance.selected.iconColor = activeColor
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
                
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
            
            // Floating action button with Pinterest-inspired styling
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showingNewTripSheet = true
                    }) {
                        ZStack {
                            // Primary circle
                            Circle()
                                .fill(Color.buttonBackground)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                            
                            // Plus icon
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color.buttonText)
                        }
                    }
                    .padding(.bottom, 85)
                    .accessibilityLabel("Create New Trip")
                    
                    Spacer().frame(height: 0)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .fullScreenCover(isPresented: $showingNewTripSheet) {
                    NavigationView {
                        CreateTripView()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

