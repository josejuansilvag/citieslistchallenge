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
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: City.self, configurations: config)
        
        repository = CityRepository(modelContext: modelContainer.mainContext)
        dataStore = DataStore(
            repository: repository,
            networkService: MockNetworkService()
        )
        
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
        let result = await repository.fetchCities(matching: "", onlyFavorites: false, page: 0, pageSize: 10)
        
        XCTAssertEqual(result.cities.count, 9, "Should fetch all 9 test cities")
        XCTAssertEqual(result.totalMatchingCount, 9, "Total count should be 9")
    }
    
    @MainActor
    func testRepositoryFetchWithPrefix() async {
        let result = await repository.fetchCities(matching: "A", onlyFavorites: false, page: 0, pageSize: 10)
        
        XCTAssertEqual(result.cities.count, 4, "Should fetch 4 cities starting with 'A'")
        XCTAssertTrue(result.cities.allSatisfy { $0.name.hasPrefix("A") })
    }
    
    @MainActor
    func testRepositoryFetchCaseInsensitive() async {
        let result = await repository.fetchCities(matching: "a", onlyFavorites: false, page: 0, pageSize: 10)
        
        XCTAssertEqual(result.cities.count, 4, "Should fetch 4 cities with lowercase 'a'")
        XCTAssertTrue(result.cities.allSatisfy { $0.name.lowercased().hasPrefix("a") })
    }
    
    @MainActor
    func testRepositoryPagination() async {
        let firstPage = await repository.fetchCities(matching: "", onlyFavorites: false, page: 0, pageSize: 5)
        let secondPage = await repository.fetchCities(matching: "", onlyFavorites: false, page: 1, pageSize: 5)
        
        XCTAssertEqual(firstPage.cities.count, 5, "First page should have 5 cities")
        XCTAssertEqual(secondPage.cities.count, 4, "Second page should have 4 cities")
        XCTAssertEqual(firstPage.totalMatchingCount, 9, "Total count should be 9")
    }
    
    @MainActor
    func testRepositoryToggleFavorite() async {
        let initialResult = await repository.fetchCities(matching: "", onlyFavorites: true, page: 0, pageSize: 10)
        XCTAssertEqual(initialResult.cities.count, 0, "Should have no favorites initially")
        await repository.toggleFavorite(forCityID: 1)
        let afterToggle = await repository.fetchCities(matching: "", onlyFavorites: true, page: 0, pageSize: 10)
        XCTAssertEqual(afterToggle.cities.count, 1, "Should have 1 favorite after toggle")
        XCTAssertEqual(afterToggle.cities.first?.id, 1, "Should be Alabama")
    }
    
    @MainActor
    func testRepositoryFetchFavoritesOnly() async {
        await repository.toggleFavorite(forCityID: 1) // Alabama
        await repository.toggleFavorite(forCityID: 5) // Sydney
        
        let result = await repository.fetchCities(matching: "", onlyFavorites: true, page: 0, pageSize: 10)
        
        XCTAssertEqual(result.cities.count, 2, "Should fetch only 2 favorite cities")
        XCTAssertTrue(result.cities.allSatisfy { $0.isFavorite })
    }
    
    @MainActor
    func testRepositorySearchWithFavorites() async {
        await repository.toggleFavorite(forCityID: 1)
        
        let result = await repository.fetchCities(matching: "A", onlyFavorites: true, page: 0, pageSize: 10)
        
        XCTAssertEqual(result.cities.count, 1, "Should fetch only Alabama as favorite starting with 'A'")
        XCTAssertEqual(result.cities.first?.name, "Alabama")
        XCTAssertTrue(result.cities.first?.isFavorite ?? false)
    }

    // MARK: - DataStore Tests
    
    @MainActor
    func testDataStoreSearchCities() async {
        let result = await dataStore.searchCities(prefix: "New", onlyFavorites: false, page: 0, pageSize: 10)
        
        XCTAssertEqual(result.cities.count, 2, "Should find New York and newark")
        XCTAssertTrue(result.cities.contains { $0.name == "New York" })
        XCTAssertTrue(result.cities.contains { $0.name == "newark" })
    }
    
    @MainActor
    func testDataStoreToggleFavorite() async {
        await dataStore.toggleFavorite(forCityID: 1)
        
        let result = await dataStore.searchCities(prefix: "", onlyFavorites: true, page: 0, pageSize: 10)
        XCTAssertEqual(result.cities.count, 1, "Should have 1 favorite after toggle")
    }
    
    @MainActor
    func testDataStoreClearAllData() async {
        let initialCount = await repository.getCitiesCount()
        XCTAssertEqual(initialCount, 9, "Should have 9 cities initially")
        
        await dataStore.clearAllData()
        
        let afterClearCount = await repository.getCitiesCount()
        XCTAssertEqual(afterClearCount, 0, "Should have 0 cities after clear")
    }
}

