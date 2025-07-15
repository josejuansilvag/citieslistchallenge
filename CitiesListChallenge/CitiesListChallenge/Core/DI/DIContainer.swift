//
//  DIContainer.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

// MARK: - DIContainer Implementation
/// Contenedor de dependencias que implementa DIContainerProtocol
@MainActor
final class DIContainer: DIContainerProtocol {
    private let modelContainer: ModelContainer
    private let useMockData: Bool
    
    // MARK: - Services
    private lazy var networkService: NetworkServiceProtocol = {
        if useMockData {
            return MockNetworkService()
        } else {
            return NetworkService()
        }
    }()
    
    private lazy var cityRepository: CityRepositoryProtocol = {
        if useMockData {
            return MockCityRepository()
        } else {
            return CityRepository(modelContext: modelContainer.mainContext)
        }
    }()
    
    private lazy var dataStore: DataStoreProtocol = {
        return DataStore(repository: cityRepository, networkService: networkService)
    }()
    
    init(modelContainer: ModelContainer, useMockData: Bool) {
        self.modelContainer = modelContainer
        self.useMockData = useMockData
    }
    
    // MARK: - ViewModel Creation
    func makeCityListViewModel() -> CityListViewModel {
        return CityListViewModel(dataStore: dataStore)
    }
    
    func makeCityDetailViewModel(for city: City) -> CityDetailViewModel {
        return CityDetailViewModel(city: city)
    }
    
    // MARK: - Service Creation
    func makeDataStore() -> DataStoreProtocol {
        return dataStore
    }
    
    // MARK: - Future Extensions
    /// Para futuras expansiones, agregar aquí:
    ///
    /// ```swift
    /// func makeSettingsService() -> SettingsServiceProtocol {
    ///     return SettingsService()
    /// }
    ///
    ///
    /// func makeSettingsViewModel() -> SettingsViewModel {
    ///     let settingsService = makeSettingsService()
    ///     return SettingsViewModel(settingsService: settingsService)
    /// }
    ///
    /// ```
}
