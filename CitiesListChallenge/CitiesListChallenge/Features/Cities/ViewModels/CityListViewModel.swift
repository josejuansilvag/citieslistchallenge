//
//  CityListViewModel.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData

@Observable @MainActor
final class CityListViewModel {
    private let dataStore: DataStoreProtocol
    private var searchTask: Task<Void, Never>?
    
    var searchText: String = "" {
        didSet {
            debounceSearch()
        }
    }
    
    var showOnlyFavorites: Bool = false {
        didSet {
            debounceSearch()
        }
    }
    
    var cities: [City] = []
    var isLoading = false
    var errorMessage: String?
    var hasMorePages = true
    
    private let pageSize = 50
    private var currentPage = 0
    private var hasInitialized = false
    
    init(dataStore: DataStoreProtocol) {
        self.dataStore = dataStore
    }
    
    /// DEBOUNCED SEARCH: Optimized for UI Responsiveness
    /// This function implements debouncing to prevent excessive database calls
    /// while maintaining a responsive user experience. Here's why this is crucial:
    /// 
    /// Reduces Database Load: Only searches after user stops typing
    /// Smooth UI: Prevents excessive list updates while typing
    /// Battery Efficiency: Reduces unnecessary CPU/network usage
    /// 
    private func debounceSearch() {
        //CANCEL PREVIOUS: Prevent race conditions and unnecessary work
        searchTask?.cancel()
        
        // SCHEDULE NEW SEARCH: With debouncing delay
        searchTask = Task {
            // Wait for user to stop typing
            try? await Task.sleep(for: .milliseconds(300))
            
            // EXECUTE ONLY IF NOT CANCELLED: User stopped typing
            if !Task.isCancelled {
                await MainActor.run {
                    resetAndLoadFirstPage()
                }
            }
        }
    }
    
    func resetAndLoadFirstPage() {
        currentPage = 0
        hasMorePages = true
        Task {
            await loadNextPage()
        }
    }
    
    func loadInitialDataIfNeeded() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        isLoading = true
        await dataStore.prepareDataStore()
        isLoading = false
        
        /// Reset y cargar primera página de forma async
        currentPage = 0
        hasMorePages = true
        await loadNextPage()
    }
    
    func loadNextPage() async {
        guard hasMorePages && !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        let result = await dataStore.searchCities(
            prefix: searchText,
            onlyFavorites: showOnlyFavorites,
            page: currentPage,
            pageSize: pageSize
        )
        
        cities = currentPage == 0 ? result.cities : cities + result.cities
        hasMorePages = result.cities.count == pageSize
        currentPage += 1
        isLoading = false
    }
    
    func toggleFavorite(forCityID cityID: Int) {
        Task {
            await dataStore.toggleFavorite(forCityID: cityID)
            resetAndLoadFirstPage()
        }
    }
}
