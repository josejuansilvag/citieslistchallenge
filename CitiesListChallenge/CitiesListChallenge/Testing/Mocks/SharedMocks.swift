//
//  SharedMocks.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import Foundation
import SwiftData

// MARK: - Mock Dependencies for Testing and UI Testing

@MainActor
final class MockNetworkClient: NetworkClientProtocol {
    var shouldFail = false
    var mockData: Data = Data()
    
    init() {
        if ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting") {
            self.mockData = MockDataSetup.mockData
        }
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint, parameters: RequestParameters?) async throws -> T {
        if shouldFail {
            throw NetworkError.requestFailed(NSError(domain: "Mock", code: 500, userInfo: nil))
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: mockData)
    }
    
    func request(_ endpoint: APIEndpoint, parameters: RequestParameters?) async throws -> Data {
        if shouldFail {
            throw NetworkError.requestFailed(NSError(domain: "Mock", code: 500, userInfo: nil))
        }
        return mockData
    }
}

@MainActor
final class MockNetworkService: NetworkServiceProtocol {
    private let networkClient: NetworkClientProtocol
    
    var shouldFail: Bool {
        get {
            (networkClient as? MockNetworkClient)?.shouldFail ?? false
        }
        set {
            if let client = networkClient as? MockNetworkClient {
                client.shouldFail = newValue
            }
        }
    }
    
    init(networkClient: NetworkClientProtocol? = nil) {
        self.networkClient = networkClient ?? MockNetworkClient()
    }
    
    func downloadCityData() async throws -> [CityJSON] {
        return try await networkClient.request(.cities, parameters: nil)
    }
    
    func getWeather(lat: Double, lon: Double) async throws -> WeatherInfo {
        let sample = WeatherInfo(
            location: Location(
                name: "Test City",
                region: "TestRegion",
                country: "Test Country",
                lat: lat,
                lon: lon,
                localtime: "2024-12-01 10:00"
            ),
            current: CurrentWeather(
                temp_c: 22.0,
                feelslike_c: 22.0,
                humidity: 50,
                pressure_mb: 1013.0,
                wind_kph: 10.0,
                wind_degree: 180,
                uv: 5.0,
                vis_km: 10.0,
                condition: WeatherCondition(
                    text: "Sunny",
                    icon: "https://cdn.weatherapi.com/weather/64x64/day/113.png",
                    code: 10
                )
            )
        )
        return sample
    }
}

@MainActor
final class MockCityRepository: CityRepositoryProtocol {
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
        print("MockCityRepository: Retornando \(paginatedCities.count) ciudades de \(filteredCities.count) total")
        return SearchResult(cities: paginatedCities, totalMatchingCount: filteredCities.count)
    }
    
    func toggleFavorite(forCityID cityID: Int) async {
        if let index = mockCities.firstIndex(where: { $0.id == cityID }) {
            mockCities[index].isFavorite.toggle()
        }
    }
    
    func saveCities(_ cities: [CityJSON]) async {
        let cityObjects = cities.compactMap { City(from: $0) }
        mockCities.append(contentsOf: cityObjects)
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

@MainActor
final class MockDataStore: DataStoreProtocol {
    private let repository: CityRepositoryProtocol
    private let networkService: NetworkServiceProtocol
    var isDataLoaded = false
    
    init(repository: CityRepositoryProtocol, networkService: NetworkServiceProtocol) {
        print("MockDataStore: Constructor llamado")
        self.repository = repository
        self.networkService = networkService
    }
    
    func prepareDataStore(progressCallback: @escaping (DataLoadingProgress) -> Void) async {
        print("MockDataStore: prepareDataStore llamado")
        if isDataLoaded {
            print("MockDataStore: Ya está cargado, retornando")
            await MainActor.run {
                progressCallback(.completed)
            }
            return
        }
        
        // Simular progreso para el mock
        await MainActor.run {
            progressCallback(.downloadingCities)
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
        
        do {
            let cities = try await networkService.downloadCityData()
            await MainActor.run {
                progressCallback(.processingCities(total: cities.count, current: 0))
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos
            
            await repository.saveCitiesFromJSON(cities)
            await MainActor.run {
                progressCallback(.savingCities(total: cities.count, current: cities.count))
            }
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 segundos
            
            isDataLoaded = true
            await MainActor.run {
                progressCallback(.completed)
            }
            print("MockDataStore: Datos preparados")
        } catch {
            await MainActor.run {
                progressCallback(.error(error.localizedDescription))
            }
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
    
    func saveCities(_ cities: [CityJSON]) async {
        await repository.saveCitiesFromJSON(cities)
    }
} 
