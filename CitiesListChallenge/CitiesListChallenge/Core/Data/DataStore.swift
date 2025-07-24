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
    
    // MARK: - Progress Reporting
    private var progressCallback: ((DataLoadingProgress) -> Void)?
    private let progressUpdateFrequency = 3 // Update every 3 chunks
    
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
    
    func prepareDataStore(progressCallback: @escaping (DataLoadingProgress) -> Void) async {
        self.progressCallback = progressCallback
        
        // Verificar si ya hay ciudades en la base de datos
        let count = await repository.getCitiesCount()
        if count > 0 {
            await MainActor.run {
                progressCallback(.completed)
            }
            return
        }
        await downloadAndStoreCities()
    }
    
    private func downloadAndStoreCities() async {
        do {
            // Step 1: Download cities
            print("📥 Starting download of cities data...")
            await MainActor.run {
                progressCallback?(.downloadingCities)
            }
            let cityJSONs = try await networkService.downloadCityData()
            
            // Step 2: Clear existing data
            await repository.clearAllCities()
            
            // Step 3: Process and save in chunks
            let chunks = cityJSONs.chunked(into: chunkSize)
            let totalChunks = chunks.count
            
            print("⚙️ Processing \(cityJSONs.count) cities in \(totalChunks) chunks...")
            await MainActor.run {
                progressCallback?(.processingCities(total: totalChunks, current: 0))
            }
            
            for (index, chunk) in chunks.enumerated() {
                await self.repository.saveCitiesFromJSON(chunk)
                
                // Update progress every N chunks or on the last chunk
                let shouldUpdate = (index + 1) % progressUpdateFrequency == 0 || (index + 1) == totalChunks
                if shouldUpdate {
                    await MainActor.run {
                        progressCallback?(.savingCities(total: totalChunks, current: index + 1))
                    }
                }
            }
            
            // Ensure we show 100% completion before marking as completed
            await MainActor.run {
                progressCallback?(.savingCities(total: totalChunks, current: totalChunks))
            }
            
            // Small delay to show 100% before completing
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            print("✅ Data loading completed successfully!")
            await MainActor.run {
                progressCallback?(.completed)
            }
        } catch {
            await MainActor.run {
                progressCallback?(.error(error.localizedDescription))
            }
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


