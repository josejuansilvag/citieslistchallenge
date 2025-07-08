//
//  City.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftData
import Foundation

@Model
final class City {
    @Attribute(.unique) var id: Int
    var name: String
    var country: String
    var coord_lon: Double
    var coord_lat: Double
    var isFavorite: Bool = false

    // Computed property for display: "City, Country"
    var displayName: String {
        "\(name), \(country)"
    }

    // Computed property for coordinates display: "Lat: X, Lon: Y"
    var coordinatesString: String {
        String(format: "Lat: %.4f, Lon: %.4f", coord_lat, coord_lon)
    }

    init(id: Int, name: String, country: String, coord_lon: Double, coord_lat: Double, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.country = country
        self.coord_lon = coord_lon
        self.coord_lat = coord_lat
        self.isFavorite = isFavorite
    }
}

struct CityJSON: Decodable {
    let country: String
    let name: String
    let _id: Int
    let coord: CoordinateJSON
}

struct CoordinateJSON: Decodable {
    let lon: Double
    let lat: Double
}
