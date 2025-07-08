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
    private let initialDataLoadedKey = "initialDataLoaded_v2"
    private var startTime: TimeInterval = 0
    private let processingGroup = DispatchGroup()
    private let chunkSize = 2000
    
    private let defaultSortDescriptor: [SortDescriptor<City>] = [
        SortDescriptor(\City.name),
        SortDescriptor(\City.country)
    ]

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

    @MainActor
    func prepareDataStore() async {
        startTime = Date().timeIntervalSince1970
        print("🔄 Starting data store preparation...")
        print("📊 Configuration: Chunk Size: \(chunkSize)")
        
        if UserDefaults.standard.bool(forKey: initialDataLoadedKey) {
            isDataLoaded = true
            printTimeElapsed(message: "Data already loaded")
            return
        }
        
        let fetchDescriptor = FetchDescriptor<City>()
        do {
            let count = try modelContext.fetchCount(fetchDescriptor)
            if count > 0 {
                UserDefaults.standard.set(true, forKey: initialDataLoadedKey)
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
            // Download cities
            startTime = Date().timeIntervalSince1970
            let cityJSONs = try await networkService.downloadCityData()
            printTimeElapsed(message: "Downloaded city data")
            print("📊 Total cities to process: \(cityJSONs.count)")

            // Get current favorites
            startTime = Date().timeIntervalSince1970
            var favoritedCityIDs = Set<Int>()
            var favFetchDescriptor = FetchDescriptor<City>(predicate: #Predicate<City> { $0.isFavorite })
            favFetchDescriptor.propertiesToFetch = [\.id]
            if let currentFavorites = try? modelContext.fetch(favFetchDescriptor) {
                currentFavorites.forEach { favoritedCityIDs.insert($0.id) }
            }
            printTimeElapsed(message: "Retrieved current favorites")

            // Delete existing cities
            startTime = Date().timeIntervalSince1970
            try modelContext.delete(model: City.self)
            printTimeElapsed(message: "Deleted existing cities")

            // Create all city objects in parallel
            startTime = Date().timeIntervalSince1970
            let cities = await withTaskGroup(of: [City].self) { group in
                let processorCount = ProcessInfo.processInfo.processorCount
                let citiesPerProcessor = cityJSONs.count / processorCount + 1
                
                for processorIndex in 0..<processorCount {
                    let start = processorIndex * citiesPerProcessor
                    let end = min(start + citiesPerProcessor, cityJSONs.count)
                    if start < cityJSONs.count {
                        group.addTask {
                            let processorChunk = cityJSONs[start..<end]
                            return processorChunk.map { json in
                                City(id: json._id,
                                     name: json.name,
                                     country: json.country,
                                     coord_lon: json.coord.lon,
                                     coord_lat: json.coord.lat,
                                     isFavorite: favoritedCityIDs.contains(json._id))
                            }
                        }
                    }
                }
                
                var allCities: [City] = []
                for await cities in group {
                    allCities.append(contentsOf: cities)
                }
                return allCities
            }
            printTimeElapsed(message: "Created all city objects in parallel")
            
            // Save cities in parallel chunks
            startTime = Date().timeIntervalSince1970
            let chunks = cities.chunked(into: chunkSize)
            let totalChunks = chunks.count
            
            try await withThrowingTaskGroup(of: Int.self) { group in
                for (index, chunk) in chunks.enumerated() {
                    group.addTask {
                        let context = ModelContext(self.modelContext.container)
                        var savedCount = 0
                        
                        for city in chunk {
                            context.insert(city)
                            savedCount += 1
                        }
                        
                        try context.save()
                        print("📂 Saved chunk \(index + 1) / \(totalChunks) - \(chunk.count) cities")
                        return savedCount
                    }
                }
                
                let totalSaved = try await group.reduce(0, +)
                print("✅ Total cities saved: \(totalSaved)")
            }
            
            printTimeElapsed(message: "Inserted and saved all cities")
            
            UserDefaults.standard.set(true, forKey: initialDataLoadedKey)
            isDataLoaded = true
            print("✅ Data store preparation completed successfully")
        } catch {
            print("❌ Error during full refresh and store cities: \(error)")
        }
    }

    @MainActor
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) -> (cities: [City], totalMatchingCount: Int) {
        guard page >= 0, pageSize > 0 else {
            return ([], 0)
        }

        let lowercasedPrefix = prefix.lowercased()
        var finalPredicate: Predicate<City>? = nil

        if !lowercasedPrefix.isEmpty {
            if onlyFavorites {
                finalPredicate = #Predicate<City> { city in
                    city.name.localizedStandardContains(lowercasedPrefix) && city.isFavorite
                }
            } else {
                finalPredicate = #Predicate<City> { city in
                    city.name.localizedStandardContains(lowercasedPrefix)
                }
            }
        } else if onlyFavorites {
            finalPredicate = #Predicate<City> { city in city.isFavorite }
        }

        var queryDescriptor = FetchDescriptor<City>(predicate: finalPredicate, sortBy: defaultSortDescriptor)
        do {
            let totalMatchingCount = (try? modelContext.fetchCount(queryDescriptor)) ?? 0
            if totalMatchingCount == 0 {
                return ([], 0)
            }
            queryDescriptor.fetchOffset = page * pageSize
            queryDescriptor.fetchLimit = pageSize
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
            UserDefaults.standard.removeObject(forKey: initialDataLoadedKey)
            isDataLoaded = false
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}

extension DataStore {
    private func printTimeElapsed(message: String) {
        let timeElapsed = Date().timeIntervalSince1970 - startTime
        print("⏱️ \(message): \(String(format: "%.3f", timeElapsed)) seconds")
        startTime = Date().timeIntervalSince1970
    }
}

