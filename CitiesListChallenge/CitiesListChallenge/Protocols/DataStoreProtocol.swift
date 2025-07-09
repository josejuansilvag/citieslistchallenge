//
//  DataStoreProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

// MARK: - Data Store Protocol
protocol DataStoreProtocol {
    func prepareDataStore() async
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> (cities: [City], totalMatchingCount: Int)
    func toggleFavorite(forCityID cityID: Int) async
    func clearAllData() async
}

// MARK: - Data Store Result Types
struct SearchResult {
    let cities: [City]
    let totalMatchingCount: Int
}
