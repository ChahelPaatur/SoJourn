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
                        Label("Trips", systemImage: "airplane")
                    }
                    .tag(0)
                
                SharedTripsView()
                    .tabItem {
                        Label("Shared", systemImage: "person.2")
                    }
                    .tag(1)
                
                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "magnifyingglass")
                    }
                    .tag(2)
                
                CompletedTripsView()
                    .tabItem {
                        Label("Past", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(3)
                
                ProfileView()
                    .tabItem {
                        Label("Account", systemImage: "person.circle")
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
                    return traitCollection.userInterfaceStyle == .dark ? .white : .gray
                }
                
                appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
                
                // Set active tab color - yellow in dark mode, black in light mode
                let activeColor = UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? 
                        UIColor(Color.sojourYellow) : .black
                }
                
                appearance.stackedLayoutAppearance.selected.iconColor = activeColor
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
                
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
            
            // Floating plus button (positioned higher)
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showingNewTripSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .foregroundColor(Color.buttonText)
                            .frame(width: 56, height: 56)
                            .background(Color.buttonBackground)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    }
                    .padding(.bottom, 90) // Position higher than before
                    
                    Spacer().frame(height: 0) // Push button up from bottom
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

