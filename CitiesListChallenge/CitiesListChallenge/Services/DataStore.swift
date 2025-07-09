//
//  DataStore.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData

class DataStore: DataStoreProtocol {
    private let repository: CityRepositoryProtocol
    private let networkService: NetworkServiceProtocol
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
    
    init(repository: CityRepositoryProtocol, networkService: NetworkServiceProtocol) {
        self.repository = repository
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
        
        let count = await repository.getCitiesCount()
        if count > 0 {
            isInitialDataLoaded = true
            isDataLoaded = true
            printTimeElapsed(message: "Found existing cities in database")
            return
        }
        
        await downloadAndStoreCities()
    }
    
    @MainActor
    private func downloadAndStoreCities() async {
        print("🔄 Starting download and store cities (Serial Chunks Strategy)...")
        do {
            startTime = Date().timeIntervalSince1970
            let cityJSONs = try await networkService.downloadCityData()
            printTimeElapsed(message: "Downloaded city data Total cities to process: \(cityJSONs.count)")
            
            await repository.clearAllCities()
            
            startTime = Date().timeIntervalSince1970
            let chunks = cityJSONs.chunked(into: chunkSize)
            for chunk in chunks {
                await self.repository.saveCitiesFromJSON(chunk)
            }
            
            isInitialDataLoaded = true
            isDataLoaded = true
            printTimeElapsed(message: " ✅ Inserted and saved all cities")
        } catch {
            print("❌ Error during full refresh and store cities: \(error)")
        }
    }
    
    // MARK: - DataStoreProtocol Implementation
    
    @MainActor
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> (cities: [City], totalMatchingCount: Int) {
        let result = await repository.fetchCities(matching: prefix, onlyFavorites: onlyFavorites, page: page, pageSize: pageSize)
        return (result.cities, result.totalMatchingCount)
    }
    
    @MainActor
    func toggleFavorite(forCityID cityID: Int) async {
        await repository.toggleFavorite(forCityID: cityID)
    }
    
    @MainActor
    func clearAllData() async {
        await repository.clearAllCities()
        isInitialDataLoaded = false
        isDataLoaded = false
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
