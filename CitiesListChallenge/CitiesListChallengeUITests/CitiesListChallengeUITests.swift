//
//  CitiesListChallengeUITests.swift
//  CitiesListChallengeUITests
//
//  Created by Jose Juan Silva Gamino on 06/07/25.
//

import XCTest

final class UalaChallengeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Given: Launch the app with mock data argument
        app.launchArguments += ["--useMockDataForUITesting"]
    
        // When: App is launched
        app.launch()
        
        // Wait for app to fully load and stabilize
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 15), "Search field should appear after app launch")
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    @MainActor
    func testMockDataIsLoaded() async throws {
        // Given: App is loaded
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "Search field should appear after app launch")
        
        // Wait for data to load
        try await Task.sleep(nanoseconds: 3_000_000_000) // Wait 2 seconds for data to load
        
        // Then: Should have some cities loaded
        let cityCells = app.cells.allElementsBoundByIndex
        XCTAssertGreaterThan(cityCells.count, 0, "Should have at least one city cell loaded")
        
        // And: Should be able to find London in the list
        var londonFound = false
        let allStaticTexts = app.staticTexts.allElementsBoundByIndex
        for staticText in allStaticTexts {
            if staticText.label.contains("London") {
                londonFound = true
                break
            }
        }
        XCTAssertTrue(londonFound, "London should be in the mock data")
    }

    @MainActor
    func testSearchBar_FiltersList() async throws {
        // Given: The search text field exists and is ready
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "Search text field should exist")
        
        // Wait for initial data to load
        try await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds for data to load
        
        // Ensure the search field is ready for input
        searchTextField.tap()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds

        // When: Typing "London" into the search bar
        searchTextField.typeText("London")
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait for search to complete
       var londonFound = false
        let londonElement = app.staticTexts.matching(identifier: "city.name").firstMatch
        if londonElement.waitForExistence(timeout: 2) && londonElement.label == "London" {
            londonFound = true
        }
        XCTAssertTrue(londonFound, "Cell for London should appear after searching")
   }

    @MainActor
    func testFavoriteToggle_UpdatesIconAndFilters() async throws {
        // Given: App is loaded and city cells are visible
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "App should load")
        
        // Wait for cities to load
        try await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds for data to load
        
        let cityCell = app.cells.firstMatch
        XCTAssertTrue(cityCell.waitForExistence(timeout: 10), "At least one city cell should exist")

        var favoriteButton: XCUIElement?
        let favoriteButtonById = cityCell.buttons.matching(identifier: "favorite.button").firstMatch
        if favoriteButtonById.waitForExistence(timeout: 2) {
            favoriteButton = favoriteButtonById
        }
        XCTAssertNotNil(favoriteButton, "Favorite button should exist")
        
        let initialLabel = favoriteButton!.label
        let initialState = initialLabel.contains("Remove")

        // When: Tapping the favorite button
        favoriteButton!.tap()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then: The favorite icon should toggle
        let newLabel = favoriteButton!.label
        let newState = newLabel.contains("Remove")
        XCTAssertNotEqual(initialState, newState, "Favorite state should toggle")
    }

    @MainActor
    func testNavigationToDetailView() async throws {
        // Given: App is loaded and city cells are visible
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "App should load")
        
        // Wait for cities to load
        try await Task.sleep(nanoseconds: 4_000_000_000) // Wait 4 seconds for data to load
        
        let cityCell = app.cells.firstMatch
        XCTAssertTrue(cityCell.waitForExistence(timeout: 10), "At least one city cell should exist")

        var cityName: String = ""
        let cityNameElement = app.staticTexts.matching(identifier: "city.name").firstMatch
        if cityNameElement.waitForExistence(timeout: 2) {
            cityName = cityNameElement.label
        }

        // Ensure we have a city name
        XCTAssertFalse(cityName.isEmpty, "Should be able to get city name")

        // Find info button by accessibility identifier - try multiple strategies
        var infoButton: XCUIElement?
        
        let infoButtonById = cityCell.buttons.matching(identifier: "info.circle").firstMatch
        if infoButtonById.waitForExistence(timeout: 2) {
            infoButton = infoButtonById
        }
        XCTAssertNotNil(infoButton, "Info button should exist")

        // When: Tapping the info button
        infoButton!.tap()

        // Then: Navigation bar with detail view should appear
        let detailViewNavigationBar = app.navigationBars["Details: \(cityName)"]
        XCTAssertTrue(detailViewNavigationBar.waitForExistence(timeout: 10), "Detail view should appear")

        // When: Tapping Done
        let doneButton = detailViewNavigationBar.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 10), "Done button should exist")
        doneButton.tap()

        // Then: Should return to main screen
        let mainNavigationBar = app.navigationBars["Cities"]
        XCTAssertTrue(mainNavigationBar.waitForExistence(timeout: 10), "Should be back to main screen")
    }

    @MainActor
    func testNavigationToMapViewFromRowTap() async throws {
        // Given: App is loaded and city cells are visible
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "App should load")
        
        // Wait for cities to load
        try await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds for data to load
        
        let cityCell = app.cells.firstMatch
        XCTAssertTrue(cityCell.waitForExistence(timeout: 10), "At least one city cell should exist")

        // Get the city name before tapping
        var cityName: String = ""
        let cityNameElement = app.staticTexts.matching(identifier: "city.name").firstMatch
        if cityNameElement.waitForExistence(timeout: 2) {
            cityName = cityNameElement.label
        }
        XCTAssertFalse(cityName.isEmpty, "Should be able to get city name")

        // When: Tapping the city cell
        cityCell.tap()

        // Then: Map view should appear with the city name as title
        let mapViewNavigationBar = app.navigationBars[cityName]
        XCTAssertTrue(mapViewNavigationBar.waitForExistence(timeout: 10), "Map view should appear after row tap with city name: \(cityName)")

        // When: Tapping back button - look for any back button
        let backButton = mapViewNavigationBar.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 10), "Back button should exist")
        backButton.tap()

        // Then: Return to main navigation bar
        let mainNavigationBar = app.navigationBars["Cities"]
        XCTAssertTrue(mainNavigationBar.waitForExistence(timeout: 10), "Should be back to main screen")
    }

}

