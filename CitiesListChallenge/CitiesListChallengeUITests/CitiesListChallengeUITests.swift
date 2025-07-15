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
        print("UI Test: Adding launch argument --useMockDataForUITesting")
        print("UI Test: Launch arguments before launch: \(app.launchArguments)")

        // When: App is launched
        app.launch()
        
        // Wait for app to fully load
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "Search field should appear after app launch")
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testSearchBar_FiltersList() async throws {
        // Given: The search text field exists and is ready
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "Search text field should exist")
        
        // Ensure the search field is ready for input
        searchTextField.tap()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds

        // When: Typing "London" into the search bar
        searchTextField.typeText("London")
        try await Task.sleep(nanoseconds: 1_000_000_000) // Wait for search to complete

        // Then: A cell with "London" should appear
        let londonCell = app.staticTexts["London"]
        XCTAssertTrue(londonCell.waitForExistence(timeout: 10), "Cell for London should appear after searching")

        // When: Clearing the search
        let clearButton = searchTextField.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        } else {
            // Alternative: select all and delete
            searchTextField.doubleTap()
            searchTextField.typeText("")
        }

        // Then: The search field should be empty
        let value = searchTextField.value as? String ?? ""
        XCTAssertTrue(value.isEmpty || value == "Search", "Search field should be cleared")
    }

    func testFavoriteToggle_UpdatesIconAndFilters() async throws {
        // Given: App is loaded and city cells are visible
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "App should load")
        
        // Wait for cities to load
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds for data to load
        
        let cityCell = app.cells.firstMatch
        XCTAssertTrue(cityCell.waitForExistence(timeout: 10), "At least one city cell should exist")

        // Find favorite button by accessibility identifier
        let favoriteButton = cityCell.buttons.matching(identifier: "favorite.button").firstMatch
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5), "Favorite button should exist")

        let initialLabel = favoriteButton.label
        let initialState = initialLabel.contains("Remove")

        // When: Tapping the favorite button
        favoriteButton.tap()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then: The favorite icon should toggle
        let newLabel = favoriteButton.label
        let newState = newLabel.contains("Remove")
        XCTAssertNotEqual(initialState, newState, "Favorite state should toggle")
    }

    func testNavigationToDetailView() async throws {
        // Given: App is loaded and city cells are visible
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "App should load")
        
        // Wait for cities to load
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds for data to load
        
        let cityCell = app.cells.firstMatch
        XCTAssertTrue(cityCell.waitForExistence(timeout: 10), "At least one city cell should exist")

        let cityName = cityCell.staticTexts.firstMatch.label

        // Find info button by system name
        let infoButton = cityCell.buttons.matching(identifier: "info.circle").firstMatch
        XCTAssertTrue(infoButton.waitForExistence(timeout: 5), "Info button should exist")

        // When: Tapping the info button
        infoButton.tap()

        // Then: Navigation bar with detail view should appear
        let detailViewNavigationBar = app.navigationBars["Details: \(cityName)"]
        XCTAssertTrue(detailViewNavigationBar.waitForExistence(timeout: 5), "Detail view should appear")

        // When: Tapping Done
        let doneButton = detailViewNavigationBar.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Done button should exist")
        doneButton.tap()

        // Then: Should return to main screen
        let mainNavigationBar = app.navigationBars["Cities"]
        XCTAssertTrue(mainNavigationBar.waitForExistence(timeout: 5), "Should be back to main screen")
    }

    func testNavigationToMapViewFromRowTap() async throws {
        // Given: App is loaded and city cells are visible
        let searchTextField = app.searchFields.firstMatch
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 10), "App should load")
        
        // Wait for cities to load
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds for data to load
        
        let cityCell = app.cells.firstMatch
        XCTAssertTrue(cityCell.waitForExistence(timeout: 10), "At least one city cell should exist")

        // When: Tapping the city cell
        cityCell.tap()

        // Then: Map view should appear
        let mapViewNavigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(mapViewNavigationBar.waitForExistence(timeout: 5), "Map view should appear after row tap")

        // When: Tapping back button - look for any back button
        let backButton = mapViewNavigationBar.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Back button should exist")
        backButton.tap()

        // Then: Return to main navigation bar
        let mainNavigationBar = app.navigationBars["Cities"]
        XCTAssertTrue(mainNavigationBar.waitForExistence(timeout: 5), "Should be back to main screen")
    }

}

