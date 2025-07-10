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
        // Act
        await viewModel.loadInitialDataIfNeeded()
        XCTAssertEqual(viewModel.cities.count, 5, "Should load all 5 test cities")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }
    
    @MainActor
    func testInitialLoadWithJSONData() async {
        let cityJSONs = [
            CityJSON(country: "AR", name: "Buenos Aires", _id: 1, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)),
            CityJSON(country: "BR", name: "Rio de Janeiro", _id: 2, coord: CoordinateJSON(lon: -43.1729, lat: -22.9068))
        ]
        await mockDataStore.saveCitiesFromJSON(cityJSONs)
        await viewModel.loadInitialDataIfNeeded()
        XCTAssertEqual(viewModel.cities.count, 7) //5 from setup + 2 new
        XCTAssertEqual(viewModel.cities.last?.name, "Rio de Janeiro")
    }

    // MARK: - Search Functionality Tests
    
    @MainActor
    func testSearchFiltersCities() async {
        await viewModel.loadInitialDataIfNeeded()
        viewModel.searchText = "London"
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
        XCTAssertEqual(viewModel.cities.count, 1, "Should find only London")
        XCTAssertEqual(viewModel.cities.first?.name, "London")
    }
    
    @MainActor
    func testSearchCaseInsensitive() async {
        await viewModel.loadInitialDataIfNeeded()
        viewModel.searchText = "london" // lowercase
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 1, "Should find London with lowercase search")
        XCTAssertEqual(viewModel.cities.first?.name, "London")
    }
    
    @MainActor
    func testSearchEmptyStringShowsAll() async {
        await viewModel.loadInitialDataIfNeeded()
        viewModel.searchText = "London"
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 1)
        viewModel.searchText = ""
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 5, "Should show all cities when search is empty")
    }

    // MARK: - Favorites Tests
    
    @MainActor
    func testFavoritesFilter() async {
        await viewModel.loadInitialDataIfNeeded()
        viewModel.showOnlyFavorites = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 2, "Should show only 2 favorite cities")
        XCTAssertTrue(viewModel.cities.allSatisfy { $0.isFavorite })
    }
    
    @MainActor
    func testToggleFavorite() async {
        await viewModel.loadInitialDataIfNeeded()
        viewModel.toggleFavorite(forCityID: 1) // London
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertTrue(mockRepository.mockCities.first { $0.id == 1 }?.isFavorite ?? false)
    }
    
    @MainActor
    func testSearchWithFavoritesFilter() async {
        await viewModel.loadInitialDataIfNeeded()
        viewModel.showOnlyFavorites = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 2) // Only favorites
        viewModel.searchText = "New York"
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(viewModel.cities.count, 1, "Should find only New York in favorites")
        XCTAssertEqual(viewModel.cities.first?.name, "New York")
        XCTAssertTrue(viewModel.cities.first?.isFavorite ?? false)
    }

    // MARK: - Network Error Handling Tests
    
    @MainActor
    func testNetworkFailureHandling() async {
        mockNetworkService.shouldFail = true
        await viewModel.loadInitialDataIfNeeded()
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after failure")
    }

    // MARK: - Pagination Tests
    
    @MainActor
    func testPagination() async {
        let moreCities = (6...60).map { i in
            City(id: i, name: "City\(i)", country: "CO", coord_lon: Double(i), coord_lat: Double(i))
        }
        mockRepository.mockCities.append(contentsOf: moreCities)
        
        await viewModel.loadInitialDataIfNeeded()
        XCTAssertEqual(viewModel.cities.count, 50, "Should load first page of 50 items")
        XCTAssertTrue(viewModel.hasMorePages, "Should have more pages")
        await viewModel.loadNextPage()
        
        XCTAssertEqual(viewModel.cities.count, 60, "Should have loaded second page")
    }
    
    @MainActor
    func testPaginationWithSearch() async {
        let moreCities = (6...60).map { i in
            City(id: i, name: "City\(i)", country: "CO", coord_lon: Double(i), coord_lat: Double(i))
        }
        mockRepository.mockCities.append(contentsOf: moreCities)
        
        await viewModel.loadInitialDataIfNeeded()
        viewModel.searchText = "City"
        XCTAssertTrue(viewModel.hasMorePages, "Should have more pages when searching")
    }
}
