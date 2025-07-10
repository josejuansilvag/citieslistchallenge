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
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037,
            isFavorite: true
        )
        
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Buenos Aires")
        XCTAssertEqual(city.country, "AR")
        XCTAssertEqual(city.coord_lon, -58.3816)
        XCTAssertEqual(city.coord_lat, -34.6037)
        XCTAssertTrue(city.isFavorite)
    }
    
    func testCityInitializationWithDefaults() {
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Buenos Aires")
        XCTAssertEqual(city.country, "AR")
        XCTAssertEqual(city.coord_lon, -58.3816)
        XCTAssertEqual(city.coord_lat, -34.6037)
        XCTAssertFalse(city.isFavorite, "Should default to false")
    }
    
    // MARK: - Computed Properties Tests
    
    func testDisplayName() {
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        XCTAssertEqual(city.displayName, "Buenos Aires, AR")
    }
    
    func testCoordinatesString() {
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        XCTAssertEqual(city.coordinatesString, "Lat: -34.6037, Lon: -58.3816")
    }
    
    func testDisplayNameLowercased() {
        let city = City(
            id: 1,
            name: "Buenos Aires",
            country: "AR",
            coord_lon: -58.3816,
            coord_lat: -34.6037
        )
        
        XCTAssertEqual(city.displayName_lowercased, "buenos aires, ar")
    }
    
    // MARK: - JSON Initialization Tests
    
    func testCityFromJSON() {
        let cityJSON = CityJSON(
            country: "AR",
            name: "Buenos Aires",
            _id: 1,
            coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)
        )
        
        let city = City(from: cityJSON)
        
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Buenos Aires")
        XCTAssertEqual(city.country, "AR")
        XCTAssertEqual(city.coord_lon, -58.3816)
        XCTAssertEqual(city.coord_lat, -34.6037)
        XCTAssertFalse(city.isFavorite, "Should default to false when created from JSON")
    }
    
    // MARK: - JSON Struct Tests
    
    func testCityJSONDecodable() throws {
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
        let cityJSON = try JSONDecoder().decode(CityJSON.self, from: jsonData)
        
        XCTAssertEqual(cityJSON.country, "AR")
        XCTAssertEqual(cityJSON.name, "Buenos Aires")
        XCTAssertEqual(cityJSON._id, 1)
        XCTAssertEqual(cityJSON.coord.lon, -58.3816)
        XCTAssertEqual(cityJSON.coord.lat, -34.6037)
    }
    
    func testCoordinateJSONDecodable() throws {
        let jsonString = """
        {
            "lon": -58.3816,
            "lat": -34.6037
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let coordJSON = try JSONDecoder().decode(CoordinateJSON.self, from: jsonData)
        
        XCTAssertEqual(coordJSON.lon, -58.3816)
        XCTAssertEqual(coordJSON.lat, -34.6037)
    }
    
    // MARK: - Edge Cases Tests
    
    func testCityWithSpecialCharacters() {
        let city = City(
            id: 1,
            name: "São Paulo",
            country: "BR",
            coord_lon: -46.6388,
            coord_lat: -23.5505
        )
        
        XCTAssertEqual(city.displayName, "São Paulo, BR")
        XCTAssertEqual(city.displayName_lowercased, "são paulo, br")
    }
    
    func testCityWithNumbersInName() {
        let city = City(
            id: 1,
            name: "New York 2",
            country: "US",
            coord_lon: -74.0060,
            coord_lat: 40.7128
        )
        
        XCTAssertEqual(city.displayName, "New York 2, US")
        XCTAssertEqual(city.displayName_lowercased, "new york 2, us")
    }
    
    func testCityWithZeroCoordinates() {
        let city = City(
            id: 1,
            name: "Null Island",
            country: "XX",
            coord_lon: 0.0,
            coord_lat: 0.0
        )
        
        XCTAssertEqual(city.coordinatesString, "Lat: 0.0000, Lon: 0.0000")
    }
}
