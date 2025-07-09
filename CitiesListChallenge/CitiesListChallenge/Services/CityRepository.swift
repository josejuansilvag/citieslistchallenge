//
//  CityRepository.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 08/07/25.
//

import Foundation
import SwiftData

@MainActor
class CityRepository: CityRepositoryProtocol {
    private let modelContext: ModelContext
    
    private let defaultSortDescriptor: [SortDescriptor<City>] = [
        SortDescriptor(\City.name),
        SortDescriptor(\City.country)
    ]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchCities(matching prefix: String, onlyFavorites: Bool, page: Int, pageSize: Int) async -> SearchResult {
        guard page >= 0, pageSize > 0 else {
            return SearchResult(cities: [], totalMatchingCount: 0)
        }

        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var finalPredicate: Predicate<City>? = nil

        if !trimmedPrefix.isEmpty {
            let lowerBound = trimmedPrefix
            let upperBound = trimmedPrefix + "\u{FFFF}"

            if onlyFavorites {
                finalPredicate = #Predicate<City> {
                    $0.displayName_lowercased >= lowerBound &&
                    $0.displayName_lowercased < upperBound &&
                    $0.isFavorite
                }
            } else {
                finalPredicate = #Predicate<City> {
                    $0.displayName_lowercased >= lowerBound &&
                    $0.displayName_lowercased < upperBound
                }
            }
        } else if onlyFavorites {
            finalPredicate = #Predicate<City> { $0.isFavorite }
        }

        do {
            var queryDescriptor = FetchDescriptor<City>(predicate: finalPredicate, sortBy: defaultSortDescriptor)
            
            // Get total count safely
            let totalMatchingCount: Int
            do {
                totalMatchingCount = try modelContext.fetchCount(queryDescriptor)
            } catch {
                print("Error fetching count: \(error)")
                return SearchResult(cities: [], totalMatchingCount: 0)
            }
            
            guard totalMatchingCount > 0 else {
                return SearchResult(cities: [], totalMatchingCount: 0)
            }

            queryDescriptor.fetchOffset = page * pageSize
            queryDescriptor.fetchLimit = pageSize

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
    
    func saveCities(_ cities: [City]) async {
        do {
            for city in cities {
                let newCity = City(
                    id: city.id,
                    name: city.name,
                    country: city.country,
                    coord_lon: city.coord_lon,
                    coord_lat: city.coord_lat,
                    isFavorite: city.isFavorite
                )
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
            return try modelContext.fetchCount(fetchDescriptor)
        } catch {
            print("Error fetching city count: \(error)")
            return 0
        }
    }
}
