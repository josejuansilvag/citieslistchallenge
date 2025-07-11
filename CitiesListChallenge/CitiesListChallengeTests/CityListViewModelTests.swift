//
//  CityListViewModelTests.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 09/07/25.
//

import XCTest
@testable import CitiesListChallenge

final class CityListViewModelTests: XCTestCase {
    var viewModel: CityListViewModel!
    var mockDataStore: MockDataStore!
    var mockRepository: MockCityRepository!
    var mockNetworkService: MockNetworkService!

    @MainActor
    override func setUp() {
        super.setUp()
        
        // Create mock dependencies
        mockNetworkService = MockNetworkService()
        mockRepository = MockCityRepository()
        mockDataStore = MockDataStore(repository: mockRepository, networkService: mockNetworkService)
        viewModel = CityListViewModel(dataStore: mockDataStore)
        
        // Populate mock data
        let testCities = [
            City(id: 1, name: "London", country: "GB", coord_lon: 0, coord_lat: 0),
            City(id: 2, name: "Paris", country: "FR", coord_lon: 1, coord_lat: 1),
            City(id: 3, name: "New York", country: "US", coord_lon: 2, coord_lat: 2, isFavorite: true),
            City(id: 4, name: "Tokyo", country: "JP", coord_lon: 3, coord_lat: 3),
            City(id: 5, name: "Sydney", country: "AU", coord_lon: 4, coord_lat: 4, isFavorite: true),
        ]
        mockRepository.mockCities = testCities
    }

    override func tearDown() {
        viewModel = nil
        mockDataStore = nil
        mockRepository = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // MARK: - Initial Data Loading Tests
    
    @MainActor
    func testInitialLoadWithMockData() async {
        // Given: A ViewModel with 5 mock cities in the repository
        await viewModel.loadInitialDataIfNeeded()

        // Then: It should have loaded all 5 cities and finished loading
        XCTAssertEqual(viewModel.cities.count, 5, "Should load all 5 test cities")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }

    @MainActor
    func testInitialLoadWithJSONData() async {
        // Given: Two new cities added via JSON
        let cityJSONs = [
            CityJSON(country: "AR", name: "Buenos Aires", _id: 1, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)),
            CityJSON(country: "BR", name: "Rio de Janeiro", _id: 2, coord: CoordinateJSON(lon: -43.1729, lat: -22.9068))
        ]
        await mockDataStore.saveCitiesFromJSON(cityJSONs)

        // When: Initial data is loaded
        await viewModel.loadInitialDataIfNeeded()

        // Then: There should be 7 cities in total, with "Rio de Janeiro" as the last one
        XCTAssertEqual(viewModel.cities.count, 7)
        XCTAssertEqual(viewModel.cities.last?.name, "Rio de Janeiro")
    }

    @MainActor
    func testSearchFiltersCities() async {
        // Given: Initial data with all mock cities is loaded
        await viewModel.loadInitialDataIfNeeded()

        // When: Search text is set to "London"
        viewModel.searchText = "London"
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then: Only one city should match, named "London"
        XCTAssertEqual(viewModel.cities.count, 1)
        XCTAssertEqual(viewModel.cities.first?.name, "London")
    }

    @MainActor
    func testSearchCaseInsensitive() async {
        // Given: Initial data is loaded
        await viewModel.loadInitialDataIfNeeded()

        // When: Search text is set to "london" (lowercase)
        viewModel.searchText = "london"
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then: It should still find the city "London"
        XCTAssertEqual(viewModel.cities.count, 1)
        XCTAssertEqual(viewModel.cities.first?.name, "London")
    }

    @MainActor
    func testSearchEmptyStringShowsAll() async {
        // Given: A filtered search was made
        await viewModel.loadInitialDataIfNeeded()
        viewModel.searchText = "London"
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 1)

        // When: Search text is cleared
        viewModel.searchText = ""
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then: All original 5 cities should be shown
        XCTAssertEqual(viewModel.cities.count, 5)
    }

    @MainActor
    func testFavoritesFilter() async {
        // Given: Initial data with 2 favorite cities
        await viewModel.loadInitialDataIfNeeded()

        // When: Favorites filter is enabled
        viewModel.showOnlyFavorites = true
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then: Only 2 favorite cities should be visible
        XCTAssertEqual(viewModel.cities.count, 2)
        XCTAssertTrue(viewModel.cities.allSatisfy { $0.isFavorite })
    }

    @MainActor
    func testToggleFavorite() async {
        // Given: London (ID 1) is not a favorite
        await viewModel.loadInitialDataIfNeeded()

        // When: Toggle favorite status for London
        viewModel.toggleFavorite(forCityID: 1)
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then: London should now be marked as favorite
        XCTAssertTrue(mockRepository.mockCities.first { $0.id == 1 }?.isFavorite ?? false)
    }

    @MainActor
    func testSearchWithFavoritesFilter() async {
        // Given: Only favorites are being shown
        await viewModel.loadInitialDataIfNeeded()
        viewModel.showOnlyFavorites = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 2)

        // When: Search for "New York"
        viewModel.searchText = "New York"
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then: Only "New York" should match and it should be a favorite
        XCTAssertEqual(viewModel.cities.count, 1)
        XCTAssertEqual(viewModel.cities.first?.name, "New York")
        XCTAssertTrue(viewModel.cities.first?.isFavorite ?? false)
    }

    @MainActor
    func testNetworkFailureHandling() async {
        // Given: Network service is configured to fail
        mockNetworkService.shouldFail = true

        // When: Initial data is loaded
        await viewModel.loadInitialDataIfNeeded()

        // Then: ViewModel should not be in a loading state anymore
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testPagination() async {
        // Given: Add 55 more cities to the repository (total 60)
        let moreCities = (6...60).map { i in
            City(id: i, name: "City\(i)", country: "MX", coord_lon: Double(i), coord_lat: Double(i))
        }
        mockRepository.mockCities.append(contentsOf: moreCities)

        // When: Load initial data (first page)
        await viewModel.loadInitialDataIfNeeded()

        // Then: Only first 50 cities should be loaded initially
        XCTAssertEqual(viewModel.cities.count, 50)
        XCTAssertTrue(viewModel.hasMorePages)

        // When: Load next page
        await viewModel.loadNextPage()

        // Then: Remaining 10 cities should now be visible (total 60)
        XCTAssertEqual(viewModel.cities.count, 60)
    }

    @MainActor
    func testPaginationWithSearch() async {
        // Given: Add many cities and load initial data
        let moreCities = (6...60).map { i in
            City(id: i, name: "City\(i)", country: "MX", coord_lon: Double(i), coord_lat: Double(i))
        }
        mockRepository.mockCities.append(contentsOf: moreCities)
        await viewModel.loadInitialDataIfNeeded()

        // When: Search for cities that match "City"
        viewModel.searchText = "City"

        // Then: ViewModel should indicate more pages available
        XCTAssertTrue(viewModel.hasMorePages)
    }

}
