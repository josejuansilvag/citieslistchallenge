//
//  CityRepositoryProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

// MARK: - City Repository Protocol
protocol CityRepositoryProtocol {
    func fetchCities(matching prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> SearchResult
    func toggleFavorite(forCityID cityID: Int) async
    func saveCities(_ cities: [CityJSON]) async
    func saveCitiesFromJSON(_ cityJSONs: [CityJSON]) async
    func clearAllCities() async
    func getCitiesCount() async -> Int
}

// MARK: - Repository Errors
enum RepositoryError: Error {
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case invalidData
}
