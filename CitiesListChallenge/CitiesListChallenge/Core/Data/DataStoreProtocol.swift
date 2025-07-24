//
//  DataStoreProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

// MARK: - Data Loading Progress
enum DataLoadingProgress: Equatable {
    case idle
    case downloadingCities
    case processingCities(total: Int, current: Int)
    case savingCities(total: Int, current: Int)
    case completed
    case error(String)
    
    var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .downloadingCities:
            return "Downloading cities data..."
        case .processingCities(let total, let current):
            return "Processing cities... \(current)/\(total)"
        case .savingCities(let total, let current):
            return "Saving cities... \(current)/\(total)"
        case .completed:
            return "Data loaded successfully"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var progress: Double {
        switch self {
        case .idle, .downloadingCities, .error:
            return 0.0
        case .processingCities(let total, let current):
            return total > 0 ? Double(current) / Double(total) : 0.0
        case .savingCities(let total, let current):
            return total > 0 ? Double(current) / Double(total) : 0.0
        case .completed:
            return 1.0
        }
    }
    
    var isIndeterminate: Bool {
        switch self {
        case .idle, .downloadingCities, .error:
            return true
        case .processingCities, .savingCities, .completed:
            return false
        }
    }
}

// MARK: - Data Store Protocol
@MainActor
protocol DataStoreProtocol {
    func prepareDataStore(progressCallback: @escaping (DataLoadingProgress) -> Void) async
    func searchCities(prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> (cities: [City], totalMatchingCount: Int)
    func toggleFavorite(forCityID cityID: Int) async
    func clearAllData() async
}

// MARK: - Data Store Result Types
struct SearchResult {
    let cities: [City]
    let totalMatchingCount: Int
}
