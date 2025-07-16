//
//  CityRepository.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

@MainActor
final class CityRepository: CityRepositoryProtocol {
    private let modelContext: ModelContext
    
    private let defaultSortDescriptor: [SortDescriptor<City>] = [
        SortDescriptor(\City.name),
        SortDescriptor(\City.country)
    ]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// OPTIMIZED PREFIX SEARCH IMPLEMENTATION
    /// 
    /// This function implements a highly optimized database-level prefix search that provides
    /// O(log n) complexity instead of O(n) for in-memory filtering. 
    /// 
    /// PERFORMANCE BENEFITS:
    /// 1. Database Indexing: Uses SwiftData's B-tree indexing on displayName_lowercased
    /// 2. Range Queries: Leverages SQLite's efficient range operations
    /// 3. Memory Efficiency: Only loads matching results, not entire dataset
    /// 4. Pagination: Reduces memory footprint for large result sets
    /// 
    /// HOW THE ALGORITHM WORKS:
    /// 1. Pre-processing: Trim whitespace and convert to lowercase for consistency
    /// 2. Range Construction: Create upper/lower bounds using Unicode boundaries
    /// 3. Database Query: Use SwiftData predicates for efficient filtering
    /// 4. Pagination: Apply offset/limit for memory-efficient loading
    /// 
    func fetchCities(matching prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> SearchResult {
        // Input validation for pagination parameters
        guard page >= 0, pageSize > 0 else {
            return SearchResult(cities: [], totalMatchingCount: 0)
        }

        // PRE-PROCESSING: Normalize search input
        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var finalPredicate: Predicate<City>? = nil

        if !trimmedPrefix.isEmpty {
            // We create a range query using Unicode boundaries:
            // - lowerBound: The exact prefix we're looking for
            // - upperBound: prefix + "\u{FFFF}" (highest Unicode character)
            // 
            // This ensures we get ALL strings that start with our prefix
            // Example: prefix "lon" will match "London", "Long Beach", etc.
            let lowerBound = trimmedPrefix
            let upperBound = trimmedPrefix + "\u{FFFF}"

            if onlyFavorites {
                finalPredicate = #Predicate<City> {
                    $0.displayName_lowercased >= lowerBound &&
                    $0.displayName_lowercased < upperBound &&
                    $0.isFavorite
                }
            } else {
                // PURE PREFIX SEARCH: Most efficient for general searches
                finalPredicate = #Predicate<City> {
                    $0.displayName_lowercased >= lowerBound &&
                    $0.displayName_lowercased < upperBound
                }
            }
        } else if onlyFavorites {
            //FAVORITES-ONLY SEARCH: When no prefix is provided
            finalPredicate = #Predicate<City> { $0.isFavorite }
        }

        do {
            var queryDescriptor = FetchDescriptor<City>(predicate: finalPredicate, sortBy: defaultSortDescriptor)
            let totalMatchingCount: Int
            do {
                totalMatchingCount = try modelContext.fetchCount(queryDescriptor)
            } catch {
                print("Error fetching count: \(error)")
                return SearchResult(cities: [], totalMatchingCount: 0)
            }
            
            // 🚫 EARLY EXIT: If no matches, return immediately
            // This prevents unnecessary pagination calculations
            guard totalMatchingCount > 0 else {
                return SearchResult(cities: [], totalMatchingCount: 0)
            }

            // Pagination parameters:
            // - fetchOffset: Skip previous pages (page * pageSize)
            // - fetchLimit: Only load current page (pageSize)
            // 
            // This ensures we only load the data we need, keeping memory usage
            // constant regardless of total dataset size
            queryDescriptor.fetchOffset = page * pageSize
            queryDescriptor.fetchLimit = pageSize

            // EXECUTE FINAL QUERY
            let cities = try modelContext.fetch(queryDescriptor)
            return SearchResult(cities: cities, totalMatchingCount: totalMatchingCount)
        } catch {
            print("Error in fetchCities: \(error)")
            return SearchResult(cities: [], totalMatchingCount: 0)
        }
    }
    
    func toggleFavorite(forCityID cityID: Int) async {
        let predicate = #Predicate<City> { $0.id == cityID }
        var fetchDescriptor = FetchDescriptor<City>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        do {
            if let cityToUpdate = try modelContext.fetch(fetchDescriptor).first {
                cityToUpdate.isFavorite.toggle()
                try modelContext.save()
            }
        } catch {
            print("Error toggling favorite status: \(error)")
        }
    }
    
    func saveCitiesFromJSON(_ cityJSONs: [CityJSON]) async {
        do {
            for cityJSON in cityJSONs {
                let newCity = City(from: cityJSON)
                modelContext.insert(newCity)
            }
            try modelContext.save()
        } catch {
            print("Error saving cities from JSON: \(error)")
        }
    }
    
    func saveCities(_ cities: [CityJSON]) async {
        do {
            for cityJSON in cities {
                let newCity = City(from: cityJSON)
                modelContext.insert(newCity)
            }
            try modelContext.save()
        } catch {
            print("Error saving cities: \(error)")
        }
    }
    
    func clearAllCities() async {
        do {
            try modelContext.delete(model: City.self)
        } catch {
            print("Error clearing cities: \(error)")
        }
    }
    
    func getCitiesCount() async -> Int {
        do {
            let fetchDescriptor = FetchDescriptor<City>()
            let count = try modelContext.fetchCount(fetchDescriptor)
            return count
        } catch {
            print("Error fetching city count: \(error)")
            return 0
        }
    }
}
