//
//  SoJournApp.swift
//  SoJourn
//
//  Created by Chahel Paatur on 2/23/25.
//

import SwiftUI
import MapboxMaps

@main
struct SoJournApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var tripManager = TripManager.shared
    
    init() {
        // Initialize Mapbox SDK using our configuration class
        MapboxConfiguration.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(tripManager)
                .preferredColorScheme(.dark)
        }
    }
}
