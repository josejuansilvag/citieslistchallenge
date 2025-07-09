//
//  DataStore.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData

class DataStore {
    private let modelContext: ModelContext
    private let networkService: NetworkService
    private var isDataLoaded = false
    private var startTime: TimeInterval = 0
    private let chunkSize = 2000
    
    private let defaultSortDescriptor: [SortDescriptor<City>] = [
        SortDescriptor(\City.name),
        SortDescriptor(\City.country)
    ]
    
    private var isInitialDataLoaded: Bool {
        get { UserDefaults.standard.bool(forKey: "initialDataLoaded") }
        set { UserDefaults.standard.set(newValue, forKey: "initialDataLoaded") }
    }
    
    init(modelContext: ModelContext, networkService: NetworkService = NetworkService()) {
        self.modelContext = modelContext
        self.networkService = networkService
        
        if ProcessInfo.processInfo.arguments.contains("--resetDataForUITesting") {
            Task { @MainActor in
                print("UITesting: Clearing data store due to launch argument.")
                await self.clearAllData()
            }
        }
    }
    
    // MARK: - Data Preparation
    
    @MainActor
    func prepareDataStore() async {
        startTime = Date().timeIntervalSince1970
        if isInitialDataLoaded {
            isDataLoaded = true
            printTimeElapsed(message: "Data already loaded")
            return
        }
        let fetchDescriptor = FetchDescriptor<City>()
        do {
            let count = try modelContext.fetchCount(fetchDescriptor)
            if count > 0 {
                isInitialDataLoaded = true
                isDataLoaded = true
                printTimeElapsed(message: "Found existing cities in database")
                return
            }
        } catch {
            print("Error fetching city count: \(error)")
        }
        await downloadAndStoreCities()
    }
    
    @MainActor
    private func downloadAndStoreCities() async {
        print("🔄 Starting download and store cities (Parallel Chunks Strategy)...")
        do {
            startTime = Date().timeIntervalSince1970
            let cityJSONs = try await networkService.downloadCityData()
            printTimeElapsed(message: "Downloaded city data Total cities to process: \(cityJSONs.count)")
            try modelContext.delete(model: City.self)
            startTime = Date().timeIntervalSince1970
            let chunks = cityJSONs.chunked(into: chunkSize)
            await withThrowingTaskGroup(of: Int.self) { group in
                for chunk in chunks {
                    group.addTask(priority: .utility) {
                        let context = ModelContext(self.modelContext.container)
                        let cities = chunk.compactMap { City(from: $0) }
                        cities.forEach { context.insert($0) }
                        try context.save()
                        return chunk.count
                    }
                }
            }
            isInitialDataLoaded = true
            isDataLoaded = true
            printTimeElapsed(message: " ✅ Inserted and saved all cities")
        } catch {
            print("❌ Error during full refresh and store cities: \(error)")
        }
    }
    
    // MARK: - Query and Favorites
    
    @MainActor
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) -> (cities: [City], totalMatchingCount: Int) {
        guard page >= 0, pageSize > 0 else {
            return ([], 0)
        }

        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var finalPredicate: Predicate<City>? = nil

        if !trimmedPrefix.isEmpty {
            let lowerBound = trimmedPrefix
            let upperBound = trimmedPrefix + "\u{FFFF}"

            if onlyFavorites {
                finalPredicate = #Predicate<City> {
                    $0.displayName_lowercased >= lowerBound &&
                    $0.displayName_lowercased < upperBound &&
                    $0.isFavorite
                }
            } else {
                finalPredicate = #Predicate<City> {
                    $0.displayName_lowercased >= lowerBound &&
                    $0.displayName_lowercased < upperBound
                }
            }
        } else if onlyFavorites {
            finalPredicate = #Predicate<City> { $0.isFavorite }
        }

        var queryDescriptor = FetchDescriptor<City>(predicate: finalPredicate, sortBy: defaultSortDescriptor)

        guard let totalMatchingCount = try? modelContext.fetchCount(queryDescriptor), totalMatchingCount > 0 else {
            return ([], 0)
        }

        queryDescriptor.fetchOffset = page * pageSize
        queryDescriptor.fetchLimit = pageSize

        do {
            let cities = try modelContext.fetch(queryDescriptor)
            return (cities, totalMatchingCount)
        } catch {
            print("Error in searchCities: \(error)")
            return ([], 0)
        }
    }
    
    @MainActor
    func toggleFavorite(forCityID cityID: Int) async {
        let predicate = #Predicate<City> { $0.id == cityID }
        var fetchDescriptor = FetchDescriptor<City>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        do {
            if let cityToUpdate = try modelContext.fetch(fetchDescriptor).first {
                cityToUpdate.isFavorite.toggle()
                try modelContext.save()
            }
        } catch {
            print("Error toggling favorite status: \(error)")
        }
    }
    
    @MainActor
    func clearAllData() async {
        do {
            try modelContext.delete(model: City.self)
            isInitialDataLoaded = false
            isDataLoaded = false
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}

// MARK: - Helpers

extension DataStore {
    private func printTimeElapsed(message: String) {
        let timeElapsed = Date().timeIntervalSince1970 - startTime
        print("⏱️ \(message): \(String(format: "%.3f", timeElapsed)) seconds")
        startTime = Date().timeIntervalSince1970
    }
}
