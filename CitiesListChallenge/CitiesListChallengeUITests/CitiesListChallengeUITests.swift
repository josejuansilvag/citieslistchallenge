//
//  CitiesListChallengeUITests.swift
//  CitiesListChallengeUITests
//
//  Created by Jose Juan Silva Gamino on 06/07/25.
//

import XCTest

final class CitiesListChallengeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--resetDataForUITesting"]
        app.launchArguments += ["--useMockDataForUITesting"]
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
        
        let londonCell = await app.staticTexts["London, GB"]
        let londonExists = await londonCell.waitForExistence(timeout: 10)
        XCTAssertTrue(londonExists, "Cell for London, GB should appear after searching")
        
        await searchTextField.buttons["Clear text"].tap()
        let value = await searchTextField.value as? String
        XCTAssertEqual(value, "Search cities...")
    }
}
