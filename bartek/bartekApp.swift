//
//  bartekApp.swift
//  bartek
//
//  Created by Jakub Nowosad on 05/06/2025.
//

import SwiftUI

@main
struct bartekApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
