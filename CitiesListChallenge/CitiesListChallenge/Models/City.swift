//
//  City.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData

@Model
final class City {
    #Index([
        \City.displayName_lowercased,
        \City.isFavorite
    ])
    @Attribute(.unique) var id: Int
    var displayName_lowercased: String
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
        self.displayName_lowercased = "\(name), \(country)".lowercased()
    }
}

extension City {
    convenience init(from json: CityJSON) {
        self.init(
            id: json._id,
            name: json.name,
            country: json.country,
            coord_lon: json.coord.lon,
            coord_lat: json.coord.lat
        )
    }
}

// To conform to Decodable for JSON parsing, we use a temporary struct.
struct CityJSON: Codable, Sendable {
    let country: String
    let name: String
    let _id: Int
    let coord: CoordinateJSON
}

struct CoordinateJSON: Codable, Sendable {
    let lon: Double
    let lat: Double
}
