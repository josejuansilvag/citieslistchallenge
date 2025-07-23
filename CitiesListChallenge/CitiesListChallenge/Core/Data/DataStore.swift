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
    private let chunkSize = 2000
    
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
            return
        }
        await downloadAndStoreCities()
    }
    
    private func downloadAndStoreCities() async {
        do {
            let cityJSONs = try await networkService.downloadCityData()
            await repository.clearAllCities()
            let chunks = cityJSONs.chunked(into: chunkSize)
            print("cities downloaded: \(cityJSONs.count) starting to save")
            for (_, chunk) in chunks.enumerated() {
                await self.repository.saveCitiesFromJSON(chunk)
            }
            print("cities saved")
        } catch {
            print("❌ Error during full refresh and store cities: \(error)")
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
    }
}


