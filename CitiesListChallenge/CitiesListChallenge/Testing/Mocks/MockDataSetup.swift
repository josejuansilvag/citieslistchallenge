//
//  MockDataSetup.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import Foundation

struct MockDataSetup {
    static let mockCitiesJSON: [CityJSON] = [
        CityJSON(country: "GB", name: "London", _id: 1, coord: CoordinateJSON(lon: -0.1276, lat: 51.5074)),
        CityJSON(country: "US", name: "New York", _id: 2, coord: CoordinateJSON(lon: -74.0060, lat: 40.7128)),
        CityJSON(country: "FR", name: "Paris", _id: 3, coord: CoordinateJSON(lon: 2.3522, lat: 48.8566)),
        CityJSON(country: "JP", name: "Tokyo", _id: 4, coord: CoordinateJSON(lon: 139.6917, lat: 35.6895)),
        CityJSON(country: "AU", name: "Sydney", _id: 5, coord: CoordinateJSON(lon: 151.2093, lat: -33.8688)),
        CityJSON(country: "BR", name: "Rio de Janeiro", _id: 6, coord: CoordinateJSON(lon: -43.1729, lat: -22.9068)),
        CityJSON(country: "AR", name: "Buenos Aires", _id: 7, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)),
        CityJSON(country: "MX", name: "Mexico City", _id: 8, coord: CoordinateJSON(lon: -99.1332, lat: 19.4326)),
        CityJSON(country: "CA", name: "Toronto", _id: 9, coord: CoordinateJSON(lon: -79.3832, lat: 43.6532)),
        CityJSON(country: "DE", name: "Berlin", _id: 10, coord: CoordinateJSON(lon: 13.4050, lat: 52.5200))
    ]
    
    static var mockData: Data {
        do {
            return try JSONEncoder().encode(mockCitiesJSON)
        } catch {
            print("Error encoding mock data: \(error)")
            return Data()
        }
    }
} 