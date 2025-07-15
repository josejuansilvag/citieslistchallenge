//
//  NetworkServiceProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation

// MARK: - Network Service Protocol
@MainActor
protocol NetworkServiceProtocol {
    func downloadCityData() async throws -> [CityJSON]
}
