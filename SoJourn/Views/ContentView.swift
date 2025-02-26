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
            .accentColor(.black)
            .onAppear {
                // Set navigation bar appearance to white
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .white
                appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Floating plus button (positioned higher)
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    
                    Button {
                        showingNewTripSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 54))
                            .foregroundColor(.black)
                            .shadow(radius: 4)
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

