//
//  SearchLogicTests.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 09/07/25.
//

import XCTest
import SwiftData
@testable import CitiesListChallenge

class SearchLogicTests: XCTestCase {
    var modelContainer: ModelContainer!
    var dataStore: DataStoreProtocol!
    var repository: CityRepositoryProtocol!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        
        // Given: An in-memory SwiftData container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: City.self, configurations: config)
        
        // And: A data store initialized with mock network service
        repository = CityRepository(modelContext: modelContainer.mainContext)
        dataStore = DataStore(
            repository: repository,
            networkService: MockNetworkService()
        )
        
        // And: Populate with predefined test data
        await dataStore.clearAllData()
        try await populateTestData()
    }

    @MainActor
    private func populateTestData() async throws {
        let testCitiesJSON = [
            CityJSON(country: "US", name: "Alabama", _id: 1, coord: CoordinateJSON(lon: 1, lat: 1)),
            CityJSON(country: "US", name: "Albuquerque", _id: 2, coord: CoordinateJSON(lon: 2, lat: 2)),
            CityJSON(country: "US", name: "Anaheim", _id: 3, coord: CoordinateJSON(lon: 3, lat: 3)),
            CityJSON(country: "US", name: "Arizona", _id: 4, coord: CoordinateJSON(lon: 4, lat: 4)),
            CityJSON(country: "AU", name: "Sydney", _id: 5, coord: CoordinateJSON(lon: 5, lat: 5)),
            CityJSON(country: "FR", name: "Paris", _id: 6, coord: CoordinateJSON(lon: 6, lat: 6)),
            CityJSON(country: "GB", name: "London", _id: 7, coord: CoordinateJSON(lon: 7, lat: 7)),
            CityJSON(country: "US", name: "New York", _id: 8, coord: CoordinateJSON(lon: 8, lat: 8)),
            CityJSON(country: "US", name: "newark", _id: 9, coord: CoordinateJSON(lon: 9, lat: 9)),
        ]

        await repository.saveCitiesFromJSON(testCitiesJSON)
    }

    override func tearDown() {
        modelContainer = nil
        dataStore = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Repository Tests
    
    @MainActor
    func testRepositoryFetchAllCities() async {
        // When: Fetching all cities without filters
        let result = await repository.fetchCities(matching: "", onlyFavorites: false, page: 0, pageSize: 10)
        
        // Then: All cities should be returned
        XCTAssertEqual(result.cities.count, 9)
        XCTAssertEqual(result.totalMatchingCount, 9)
    }
    
    @MainActor
    func testRepositoryFetchWithPrefix() async {
        // When: Searching cities starting with "A"
        let result = await repository.fetchCities(matching: "A", onlyFavorites: false, page: 0, pageSize: 10)
        
        // Then: Should return only cities with prefix "A"
        XCTAssertEqual(result.cities.count, 4)
        XCTAssertTrue(result.cities.allSatisfy { $0.name.hasPrefix("A") })
    }
    
    @MainActor
    func testRepositoryFetchCaseInsensitive() async {
        // When: Searching with lowercase "a"
        let result = await repository.fetchCities(matching: "a", onlyFavorites: false, page: 0, pageSize: 10)
        
        // Then: Matching should be case-insensitive
        XCTAssertEqual(result.cities.count, 4)
        XCTAssertTrue(result.cities.allSatisfy { $0.name.lowercased().hasPrefix("a") })
    }
    
    @MainActor
    func testRepositoryPagination() async {
        // When: Fetching first and second page
        let firstPage = await repository.fetchCities(matching: "", onlyFavorites: false, page: 0, pageSize: 5)
        let secondPage = await repository.fetchCities(matching: "", onlyFavorites: false, page: 1, pageSize: 5)
        
        // Then: Pagination should split the result into pages
        XCTAssertEqual(firstPage.cities.count, 5)
        XCTAssertEqual(secondPage.cities.count, 4)
        XCTAssertEqual(firstPage.totalMatchingCount, 9)
    }
    
    @MainActor
    func testRepositoryToggleFavorite() async {
        // Given: No cities marked as favorite
        let initialResult = await repository.fetchCities(matching: "", onlyFavorites: true, page: 0, pageSize: 10)
        XCTAssertEqual(initialResult.cities.count, 0)
        
        // When: Toggling favorite on city with ID 1
        await repository.toggleFavorite(forCityID: 1)
        
        // Then: City should appear in favorites
        let afterToggle = await repository.fetchCities(matching: "", onlyFavorites: true, page: 0, pageSize: 10)
        XCTAssertEqual(afterToggle.cities.count, 1)
        XCTAssertEqual(afterToggle.cities.first?.id, 1)
    }
    
    @MainActor
    func testRepositoryFetchFavoritesOnly() async {
        // Given: Toggle favorite status for Alabama and Sydney
        await repository.toggleFavorite(forCityID: 1)
        await repository.toggleFavorite(forCityID: 5)
        
        // When: Fetching only favorite cities
        let result = await repository.fetchCities(matching: "", onlyFavorites: true, page: 0, pageSize: 10)
        
        // Then: Only favorites should be returned
        XCTAssertEqual(result.cities.count, 2)
        XCTAssertTrue(result.cities.allSatisfy { $0.isFavorite })
    }
    
    @MainActor
    func testRepositorySearchWithFavorites() async {
        // Given: Alabama is a favorite
        await repository.toggleFavorite(forCityID: 1)
        
        // When: Searching with prefix "A" and filtering favorites
        let result = await repository.fetchCities(matching: "A", onlyFavorites: true, page: 0, pageSize: 10)
        
        // Then: Only Alabama should be returned
        XCTAssertEqual(result.cities.count, 1)
        XCTAssertEqual(result.cities.first?.name, "Alabama")
        XCTAssertTrue(result.cities.first?.isFavorite ?? false)
    }

    // MARK: - DataStore Tests
    
    @MainActor
    func testDataStoreSearchCities() async {
        // When: Searching with prefix "New"
        let result = await dataStore.searchCities(prefix: "New", onlyFavorites: false, page: 0, pageSize: 10)
        
        // Then: Both "New York" and "newark" should be returned
        XCTAssertEqual(result.cities.count, 2)
        XCTAssertTrue(result.cities.contains { $0.name == "New York" })
        XCTAssertTrue(result.cities.contains { $0.name == "newark" })
    }
    
    @MainActor
    func testDataStoreToggleFavorite() async {
        // When: Toggling favorite status for city with ID 1
        await dataStore.toggleFavorite(forCityID: 1)
        
        // Then: It should appear in favorites
        let result = await dataStore.searchCities(prefix: "", onlyFavorites: true, page: 0, pageSize: 10)
        XCTAssertEqual(result.cities.count, 1)
    }
    
    @MainActor
    func testDataStoreClearAllData() async {
        // Given: 9 cities in store
        let initialCount = await repository.getCitiesCount()
        XCTAssertEqual(initialCount, 9)
        
        // When: Clearing all data
        await dataStore.clearAllData()
        
        // Then: No cities should remain
        let afterClearCount = await repository.getCitiesCount()
        XCTAssertEqual(afterClearCount, 0)
    }
}
