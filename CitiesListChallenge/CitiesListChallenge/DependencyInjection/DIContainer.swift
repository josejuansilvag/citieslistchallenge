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
    private var networkClient: NetworkClientProtocol
    private var networkService: NetworkServiceProtocol
    private var cityRepository: CityRepositoryProtocol
    private var dataStore: DataStoreProtocol
    
    init(modelContainer: ModelContainer, useMockData: Bool = false) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
        
        if useMockData {
            let mockRepository = MockCityRepository()
            mockRepository.mockCities = [
                City(id: 1, name: "London", country: "GB", coord_lon: 0, coord_lat: 0),
                City(id: 2, name: "Paris", country: "FR", coord_lon: 1, coord_lat: 1),
                City(id: 3, name: "New York", country: "US", coord_lon: 2, coord_lat: 2, isFavorite: true),
                City(id: 4, name: "Tokyo", country: "JP", coord_lon: 3, coord_lat: 3),
                City(id: 5, name: "Sydney", country: "AU", coord_lon: 4, coord_lat: 4, isFavorite: true)
            ]
            self.networkClient = MockNetworkClient()
            self.networkService = MockNetworkService(networkClient: self.networkClient)
            self.cityRepository = mockRepository
            self.dataStore = MockDataStore(repository: self.cityRepository, networkService: self.networkService)
        } else {
            self.networkClient = NetworkClient()
            self.networkService = NetworkService(networkClient: self.networkClient)
            self.cityRepository = CityRepository(modelContext: modelContext)
            self.dataStore = DataStore(repository: cityRepository, networkService: networkService)
        }
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
    
    func makeNetworkClient() -> NetworkClientProtocol {
        return networkClient
    }
    
    func makeCityRepository() -> CityRepositoryProtocol {
        return cityRepository
    }
}
