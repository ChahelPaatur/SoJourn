//
//  SoJournApp.swift
//  SoJourn
//
//  Created by Chahel Paatur on 2/23/25.
//

import SwiftUI

@main
struct SoJournApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var tripManager = TripManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(tripManager)
                .preferredColorScheme(.dark)
        }
    }
}
