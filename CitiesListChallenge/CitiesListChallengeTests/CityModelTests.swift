//
//  CityModelTests.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 09/07/25.
//

import XCTest
@testable import CitiesListChallenge

class CityModelTests: XCTestCase {
    
    // MARK: - City Initialization Tests
    
    func testCityInitialization() {
        // Given: A city initialized with all values including isFavorite
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037,
            isFavorite: true
        )
        
        // Then: All values should match the input
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Buenos Aires")
        XCTAssertEqual(city.country, "AR")
        XCTAssertEqual(city.coord_lon, -58.3816)
        XCTAssertEqual(city.coord_lat, -34.6037)
        XCTAssertTrue(city.isFavorite)
    }
    
    func testCityInitializationWithDefaults() {
        // Given: A city initialized without specifying isFavorite
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        // Then: isFavorite should default to false
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Buenos Aires")
        XCTAssertEqual(city.country, "AR")
        XCTAssertEqual(city.coord_lon, -58.3816)
        XCTAssertEqual(city.coord_lat, -34.6037)
        XCTAssertFalse(city.isFavorite, "Should default to false")
    }
    
    // MARK: - Computed Properties Tests
    
    func testDisplayName() {
        // Given: A city instance
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        // Then: displayName should combine name and country
        XCTAssertEqual(city.displayName, "Buenos Aires, AR")
    }
    
    func testCoordinatesString() {
        // Given: A city instance with specific coordinates
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        // Then: coordinatesString should format coordinates correctly
        XCTAssertEqual(city.coordinatesString, "Lat: -34.6037, Lon: -58.3816")
    }
    
    func testDisplayNameLowercased() {
        // Given: A city instance
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        // Then: displayName_lowercased should return a lowercase version
        XCTAssertEqual(city.displayName_lowercased, "buenos aires, ar")
    }
    
    // MARK: - JSON Initialization Tests
    
    func testCityFromJSON() {
        // Given: A CityJSON object
        let cityJSON = CityJSON(
            country: "AR",
            name: "Buenos Aires",
            _id: 1,
            coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)
        )
        
        // When: Converting CityJSON to City
        let city = City(from: cityJSON)
        
        // Then: All properties should match the JSON, and isFavorite should be false by default
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Buenos Aires")
        XCTAssertEqual(city.country, "AR")
        XCTAssertEqual(city.coord_lon, -58.3816)
        XCTAssertEqual(city.coord_lat, -34.6037)
        XCTAssertFalse(city.isFavorite, "Should default to false when created from JSON")
    }
    
    // MARK: - JSON Struct Tests
    
    func testCityJSONDecodable() throws {
        // Given: A valid JSON string representing a CityJSON
        let jsonString = """
        {
            "country": "AR",
            "name": "Buenos Aires",
            "_id": 1,
            "coord": {
                "lon": -58.3816,
                "lat": -34.6037
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When: Decoding the JSON
        let cityJSON = try JSONDecoder().decode(CityJSON.self, from: jsonData)
        
        // Then: All fields should be correctly decoded
        XCTAssertEqual(cityJSON.country, "AR")
        XCTAssertEqual(cityJSON.name, "Buenos Aires")
        XCTAssertEqual(cityJSON._id, 1)
        XCTAssertEqual(cityJSON.coord.lon, -58.3816)
        XCTAssertEqual(cityJSON.coord.lat, -34.6037)
    }
    
    func testCoordinateJSONDecodable() throws {
        // Given: A valid JSON string representing a CoordinateJSON
        let jsonString = """
        {
            "lon": -58.3816,
            "lat": -34.6037
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When: Decoding the JSON
        let coordJSON = try JSONDecoder().decode(CoordinateJSON.self, from: jsonData)
        
        // Then: Both longitude and latitude should be correctly parsed
        XCTAssertEqual(coordJSON.lon, -58.3816)
        XCTAssertEqual(coordJSON.lat, -34.6037)
    }
    
    // MARK: - Edge Cases Tests
    
    func testCityWithSpecialCharacters() {
        // Given: A city with special characters in its name
        let city = City(
            id: 1,
            name: "São Paulo",
            country: "BR",
            coord_lon: -46.6388,
            coord_lat: -23.5505
        )
        
        // Then: displayName and its lowercased version should be correct
        XCTAssertEqual(city.displayName, "São Paulo, BR")
        XCTAssertEqual(city.displayName_lowercased, "são paulo, br")
    }
    
    func testCityWithNumbersInName() {
        // Given: A city with numbers in its name
        let city = City(
            id: 1,
            name: "New York 2",
            country: "US",
            coord_lon: -74.0060,
            coord_lat: 40.7128
        )
        
        // Then: displayName and its lowercased version should be correct
        XCTAssertEqual(city.displayName, "New York 2, US")
        XCTAssertEqual(city.displayName_lowercased, "new york 2, us")
    }
    
    func testCityWithZeroCoordinates() {
        // Given: A city with zero coordinates
        let city = City(
            id: 1,
            name: "Null Island",
            country: "XX",
            coord_lon: 0.0,
            coord_lat: 0.0
        )
        
        // Then: coordinatesString should reflect zero values
        XCTAssertEqual(city.coordinatesString, "Lat: 0.0000, Lon: 0.0000")
    }
}
