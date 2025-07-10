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
        print("DataStore REAL: Constructor llamado")
        self.repository = repository
        self.networkService = networkService
        
        if ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting") {
            Task { @MainActor in
                print("DataStore REAL: Detectado argumento --useMockDataForUITesting, limpiando datos")
                await self.clearAllData()
            }
        }
    }
    
    // MARK: - Data Preparation
    
    @MainActor
    func prepareDataStore() async {
        print("DataStore: prepareDataStore llamado")
        
        // Verificar si ya hay ciudades en la base de datos
        let count = await repository.getCitiesCount()
        print("DataStore: Count de ciudades en BD: \(count)")
        
        if count > 0 {
            print("DataStore: Ya existen \(count) ciudades, no es necesario descargar")
            return
        }
        
        // Solo descargar si no hay ciudades
        print("DataStore: Descargando ciudades...")
        await downloadAndStoreCities()
        
        // Verificar count después de descargar
        let countAfterDownload = await repository.getCitiesCount()
        print("DataStore: Count después de descargar: \(countAfterDownload)")
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
