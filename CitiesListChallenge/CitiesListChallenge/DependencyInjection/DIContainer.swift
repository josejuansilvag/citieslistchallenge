//
//  DIContainer.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

// MARK: - Dependency Injection Container
@MainActor
class DIContainer {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // Services
    private lazy var networkService: NetworkServiceProtocol = NetworkService()
    private lazy var cityRepository: CityRepositoryProtocol = CityRepository(modelContext: modelContext)
    private lazy var dataStore: DataStoreProtocol = DataStore(repository: cityRepository, networkService: networkService)
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    // MARK: - Public Accessors
    func makeCityListViewModel() -> CityListViewModel {
        return CityListViewModel(dataStore: dataStore)
    }
    
    func makeCityDetailViewModel(for city: City) -> CityDetailViewModel {
        return CityDetailViewModel(city: city)
    }
    
    func makeDataStore() -> DataStoreProtocol {
        return dataStore
    }
    
    func makeNetworkService() -> NetworkServiceProtocol {
        return networkService
    }
    
    func makeCityRepository() -> CityRepositoryProtocol {
        return cityRepository
    }
}

// MARK: - Mock Dependencies for Testing
#if DEBUG
class MockNetworkService: NetworkServiceProtocol {
    var shouldFail = false
    var mockCities: [CityJSON] = []
    
    func downloadCityData() async throws -> [CityJSON] {
        if shouldFail {
            throw NetworkError.requestFailed(NSError(domain: "Mock", code: 500, userInfo: nil))
        }
        return mockCities
    }
}

class MockCityRepository: CityRepositoryProtocol {
    var mockCities: [City] = []
    var shouldFail = false
    
    func fetchCities(matching prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> SearchResult {
        if shouldFail {
            return SearchResult(cities: [], totalMatchingCount: 0)
        }
        
        let filteredCities = mockCities.filter { city in
            let matchesPrefix = prefix.isEmpty || city.name.lowercased().hasPrefix(prefix.lowercased())
            let matchesFavorites = !onlyFavorites || city.isFavorite
            return matchesPrefix && matchesFavorites
        }
        
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, filteredCities.count)
        let paginatedCities = Array(filteredCities[startIndex..<endIndex])
        
        return SearchResult(cities: paginatedCities, totalMatchingCount: filteredCities.count)
    }
    
    func toggleFavorite(forCityID cityID: Int) async {
        if let index = mockCities.firstIndex(where: { $0.id == cityID }) {
            mockCities[index].isFavorite.toggle()
        }
    }
    
    func saveCities(_ cities: [City]) async {
        mockCities.append(contentsOf: cities)
    }
    
    func saveCitiesFromJSON(_ cityJSONs: [CityJSON]) async {
        let cities = cityJSONs.compactMap { City(from: $0) }
        mockCities.append(contentsOf: cities)
    }
    
    func clearAllCities() async {
        mockCities.removeAll()
    }
    
    func getCitiesCount() async -> Int {
        return mockCities.count
    }
}

class MockDataStore: DataStoreProtocol {
    private let repository: CityRepositoryProtocol
    private let networkService: NetworkServiceProtocol
    var isDataLoaded = false
    
    init(repository: CityRepositoryProtocol, networkService: NetworkServiceProtocol) {
        self.repository = repository
        self.networkService = networkService
    }
    
    func prepareDataStore() async {
        if isDataLoaded { return }
        
        do {
            let cities = try await networkService.downloadCityData()
            let cityModels = cities.compactMap { City(from: $0) }
            await repository.saveCities(cityModels)
            isDataLoaded = true
        } catch {
            print("Mock DataStore error: \(error)")
        }
    }
    
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> (cities: [City], totalMatchingCount: Int) {
        let result = await repository.fetchCities(matching: prefix, onlyFavorites: onlyFavorites, page: page, pageSize: pageSize)
        return (result.cities, result.totalMatchingCount)
    }
    
    func toggleFavorite(forCityID cityID: Int) async {
        await repository.toggleFavorite(forCityID: cityID)
    }
    
    func clearAllData() async {
        await repository.clearAllCities()
        isDataLoaded = false
    }
    
    func saveCitiesFromJSON(_ cityJSONs: [CityJSON]) async {
        await repository.saveCitiesFromJSON(cityJSONs)
    }
    
    func saveCities(_ cities: [City]) async {
        await repository.saveCities(cities)
    }
}
#endif
