//
//  DataStore.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData

@MainActor
final class DataStore: DataStoreProtocol {
    private let repository: CityRepositoryProtocol
    private let networkService: NetworkServiceProtocol
    private var isDataLoaded = false
    private var startTime: TimeInterval = 0
    private let chunkSize = 2000
    
    private static let initialDataLoadedKey = "initialDataLoaded"
    
    private let defaultSortDescriptor: [SortDescriptor<City>] = [
        SortDescriptor(\City.name),
        SortDescriptor(\City.country)
    ]
    
    private var isInitialDataLoaded: Bool {
        get { UserDefaults.standard.bool(forKey: Self.initialDataLoadedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.initialDataLoadedKey) }
    }
    
    init(repository: CityRepositoryProtocol, networkService: NetworkServiceProtocol) {
        self.repository = repository
        self.networkService = networkService
        
        if ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting") {
            Task {
                await self.clearAllData()
            }
        }
    }
    
    // MARK: - Data Preparation
    
    func prepareDataStore() async {
        // Verificar si ya hay ciudades en la base de datos
        let count = await repository.getCitiesCount()
        if count > 0 {
            print("DataStore: Ya existen \(count) ciudades, no es necesario descargar")
            return
        }
        await downloadAndStoreCities()
    }
    
    private func downloadAndStoreCities() async {
        do {
            startTime = Date().timeIntervalSince1970
            let cityJSONs = try await networkService.downloadCityData()
            await repository.clearAllCities()
            let chunks = cityJSONs.chunked(into: chunkSize)
            for (_, chunk) in chunks.enumerated() {
                await self.repository.saveCitiesFromJSON(chunk)
            }
            
            isInitialDataLoaded = true
            isDataLoaded = true
        } catch {
            print("❌ Error during full refresh and store cities: \(error)")
            // Reset flags on error
            isInitialDataLoaded = false
            isDataLoaded = false
        }
    }
    
    // MARK: - DataStoreProtocol Implementation
    
   
    /// This function provides the main search interface that leverages the optimized
    /// repository implementation. It's designed to handle large datasets efficiently:
  
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> (cities: [City], totalMatchingCount: Int) {
        let result = await repository.fetchCities(matching: prefix, onlyFavorites: onlyFavorites, page: page, pageSize: pageSize)
        return (result.cities, result.totalMatchingCount)
    }
    
    func toggleFavorite(forCityID cityID: Int) async {
        await repository.toggleFavorite(forCityID: cityID)
    }
    
    func clearAllData() async {
        await repository.clearAllCities()
        isInitialDataLoaded = false
        isDataLoaded = false
    }
}


