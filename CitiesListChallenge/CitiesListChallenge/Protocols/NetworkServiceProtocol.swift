//
//  NetworkServiceProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func downloadCityData() async throws -> [CityJSON]
}

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}
