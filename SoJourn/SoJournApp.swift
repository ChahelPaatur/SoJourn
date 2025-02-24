//
//  SoJournApp.swift
//  SoJourn
//
//  Created by Chahel Paatur on 2/23/25.
//

import SwiftUI

@main
struct SoJournApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
