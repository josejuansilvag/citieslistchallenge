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
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testSearchBar_FiltersList() async throws {
        // Given: The search text field exists
        let searchTextField = await app.searchFields.firstMatch
        let exists = await searchTextField.waitForExistence(timeout: 15)
        XCTAssertTrue(exists, "Search text field should exist")

        // When: Typing "London" into the search bar
        await searchTextField.tap()
        await searchTextField.typeText("London")

        // Then: A cell with "London" should appear
        let londonCell = await app.staticTexts["London"]
        let londonExists = await londonCell.waitForExistence(timeout: 10)
        XCTAssertTrue(londonExists, "Cell for London should appear after searching")

        // When: Clearing the search
        await searchTextField.buttons["Clear text"].tap()

        // Then: The search field should reset to placeholder
        let value = await searchTextField.value as? String
        XCTAssertEqual(value, "Search")
    }

    func testFavoriteToggle_UpdatesIconAndFilters() async throws {
        // Given: Search bar and city cell exist
        let searchTextField = await app.searchFields.firstMatch
        let searchExists = await searchTextField.waitForExistence(timeout: 15)
        XCTAssertTrue(searchExists, "App should load")

        let cityCell = await app.cells.firstMatch
        let cellExists = await cityCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellExists, "At least one city cell should exist")

        // Given: A favorite button inside the city cell
        let favoriteButton = await cityCell.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "star", "star.fill")).firstMatch
        let favExists = await favoriteButton.waitForExistence(timeout: 5)
        XCTAssertTrue(favExists, "Favorite button should exist")

        let initialLabel = await favoriteButton.label
        let initialState = initialLabel == "star.fill"

        // When: Tapping the favorite button
        await favoriteButton.tap()
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then: The favorite icon should toggle
        let newLabel = await favoriteButton.label
        let newState = newLabel == "star.fill"
        XCTAssertNotEqual(initialState, newState, "Favorite state should toggle")
    }

    func testNavigationToDetailView() async throws {
        // Given: A city cell and its info button
        let cityCell = await app.cells.firstMatch
        let cellExists = await cityCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellExists, "At least one city cell should exist")

        let cityName = await cityCell.staticTexts.firstMatch.label

        let infoButton = await cityCell.buttons.matching(identifier: "info.circle").firstMatch
        let infoExists = await infoButton.waitForExistence(timeout: 5)
        XCTAssertTrue(infoExists, "Info button should exist")

        // When: Tapping the info button
        await infoButton.tap()

        // Then: Navigation bar with detail view should appear
        let detailViewNavigationBar = await app.navigationBars["Details: \(cityName)"]
        let navExists = await detailViewNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(navExists, "Detail view should appear")

        // When: Tapping Done
        await detailViewNavigationBar.buttons["Done"].tap()

        // Then: Should return to main screen
        let mainNavigationBar = await app.navigationBars["Cities"]
        let isBackToMain = await mainNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(isBackToMain, "Should be back to main screen")
    }

    func testNavigationToMapViewFromRowTap() async throws {
        // Given: App is ready and a city cell is visible
        let searchTextField = await app.searchFields.firstMatch
        let searchExists = await searchTextField.waitForExistence(timeout: 15)
        XCTAssertTrue(searchExists, "App should load")

        let cityCell = await app.cells.firstMatch
        let cellExists = await cityCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellExists, "At least one city cell should exist")

        // When: Tapping the city cell
        await cityCell.tap()

        // Then: Map view should appear
        let mapViewNavigationBar = await app.navigationBars.firstMatch
        let mapExists = await mapViewNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(mapExists, "Map view should appear after row tap")

        // When: Tapping back button labeled "Cities"
        let backButton = await mapViewNavigationBar.buttons.matching(NSPredicate(format: "label == %@", "Cities")).firstMatch
        await backButton.tap()

        // Then: Return to main navigation bar
        let mainNavigationBar = await app.navigationBars["Cities"]
        let isBackToMain = await mainNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(isBackToMain, "Should be back to main screen")
    }

}

