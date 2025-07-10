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
        
        app.launchArguments += ["--useMockDataForUITesting"]
        print("UI Test: Agregando argumento --useMockDataForUITesting")
        print("UI Test: Argumentos antes de launch: \(app.launchArguments)")
        
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testSearchBar_FiltersList() async throws {
        let searchTextField = await app.searchFields.firstMatch
        let exists = await searchTextField.waitForExistence(timeout: 15)
        XCTAssertTrue(exists, "Search text field should exist")

        await searchTextField.tap()
        await searchTextField.typeText("London")

        let londonCell = await app.staticTexts["London"]
        let londonExists = await londonCell.waitForExistence(timeout: 10)
        XCTAssertTrue(londonExists, "Cell for London should appear after searching")

        await searchTextField.buttons["Clear text"].tap()
        let value = await searchTextField.value as? String
        XCTAssertEqual(value, "Search")
    }

    func testFavoriteToggle_UpdatesIconAndFilters() async throws {
        let searchTextField = await app.searchFields.firstMatch
        let searchExists = await searchTextField.waitForExistence(timeout: 15)
        XCTAssertTrue(searchExists, "App should load")
        
        let cityCell = await app.cells.firstMatch
        let cellExists = await cityCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellExists, "At least one city cell should exist")
        
        let favoriteButton = await cityCell.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "star", "star.fill")).firstMatch
        let favExists = await favoriteButton.waitForExistence(timeout: 5)
        XCTAssertTrue(favExists, "Favorite button should exist")
        
        let initialLabel = await favoriteButton.label
        let initialState = initialLabel == "star.fill"
        
        await favoriteButton.tap()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let newLabel = await favoriteButton.label
        let newState = newLabel == "star.fill"
        XCTAssertNotEqual(initialState, newState, "Favorite state should toggle")
    }

    func testNavigationToDetailView() async throws {
        let cityCell = await app.cells.firstMatch
        let cellExists = await cityCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellExists, "At least one city cell should exist")

        let cityName = await cityCell.staticTexts.firstMatch.label

        let infoButton = await cityCell.buttons.matching(identifier: "info.circle").firstMatch
        let infoExists = await infoButton.waitForExistence(timeout: 5)
        XCTAssertTrue(infoExists, "Info button should exist")

        await infoButton.tap()

        let detailViewNavigationBar = await app.navigationBars["Details: \(cityName)"]
        let navExists = await detailViewNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(navExists, "Detail view should appear")

        await detailViewNavigationBar.buttons["Done"].tap()
        let mainNavigationBar = await app.navigationBars["Cities"]
        let isBackToMain = await mainNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(isBackToMain, "Should be back to main screen")
    }
    
    func testNavigationToMapViewFromRowTap() async throws {
        let searchTextField = await app.searchFields.firstMatch
        let searchExists = await searchTextField.waitForExistence(timeout: 15)
        XCTAssertTrue(searchExists, "App should load")
        
        let cityCell = await app.cells.firstMatch
        let cellExists = await cityCell.waitForExistence(timeout: 10)
        XCTAssertTrue(cellExists, "At least one city cell should exist")
        
        await cityCell.tap()
        
        let mapViewNavigationBar = await app.navigationBars.firstMatch
        let mapExists = await mapViewNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(mapExists, "Map view should appear after row tap")
        
        let backButton = await mapViewNavigationBar.buttons.matching(NSPredicate(format: "label == %@", "Cities")).firstMatch
        await backButton.tap()
        
        let mainNavigationBar = await app.navigationBars["Cities"]
        let isBackToMain = await mainNavigationBar.waitForExistence(timeout: 5)
        XCTAssertTrue(isBackToMain, "Should be back to main screen")
    }
}
