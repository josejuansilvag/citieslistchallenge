//
//  CitiesListChallengeApp.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 06/07/25.
//

import SwiftUI
import SwiftData

@main
struct CitiesListChallengeApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            City.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
