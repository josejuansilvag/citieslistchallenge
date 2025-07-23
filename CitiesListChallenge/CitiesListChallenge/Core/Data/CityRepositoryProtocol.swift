//
//  CityRepositoryProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

// MARK: - City Repository Protocol
@MainActor
protocol CityRepositoryProtocol {
    func fetchCities(matching prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> SearchResult
    func toggleFavorite(forCityID cityID: Int) async
    func saveCitiesFromJSON(_ cityJSONs: [CityJSON]) async
    func clearAllCities() async
    func getCitiesCount() async -> Int
}


