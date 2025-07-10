//
//  CitiesListChallengeApp.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 06/07/25.
//

import SwiftUI
import SwiftData

@main
struct UalaChallengeApp: App {
    
      var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            City.self,
        ])
        
        let useMockData = ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: useMockData)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var useMockData: Bool {
        ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    resetDataForUITesting()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func resetDataForUITesting() {
        guard useMockData else {
            print("No en modo UI testing, saltando reset de datos")
            return
        }
        
        Task {
            do {
                let context = sharedModelContainer.mainContext
                
                // Delete all existing cities
                let fetchDescriptor = FetchDescriptor<City>()
                let existingCities = try context.fetch(fetchDescriptor)
                for city in existingCities {
                    context.delete(city)
                }
                try context.save()
                
                // Re-initialize with fresh data (mock o real según argumento)
                let diContainer = DIContainer(modelContainer: sharedModelContainer, useMockData: useMockData)
                let dataStore = diContainer.makeDataStore()
                await dataStore.prepareDataStore()
            } catch {
                print("Error resetting data for UI testing: \(error)")
            }
        }
    }
}
