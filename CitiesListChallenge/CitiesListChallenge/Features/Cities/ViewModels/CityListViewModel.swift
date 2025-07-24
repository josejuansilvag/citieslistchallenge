//
//  CityListViewModel.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData

@MainActor
final class CityListViewModel: ObservableObject {
    private let dataStore: DataStoreProtocol
    private var searchTask: Task<Void, Never>?
    
    @Published var searchText: String = "" {
        didSet {
            debounceSearch()
        }
    }
    
    @Published var showOnlyFavorites: Bool = false {
        didSet {
            debounceSearch()
        }
    }
    
    @Published var cities: [City] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true
    
    // MARK: - Progress Tracking
    @Published var dataLoadingProgress: DataLoadingProgress = .idle
    
    var isDataLoading: Bool {
        switch dataLoadingProgress {
        case .idle, .completed, .error:
            return false
        case .downloadingCities, .processingCities, .savingCities:
            return true
        }
    }
    
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
        await dataStore.prepareDataStore { [weak self] (progress: DataLoadingProgress) in
            Task { @MainActor in
                guard let self = self else { return }
                
                            // Only update if the progress actually changed
            if self.dataLoadingProgress != progress {
                self.dataLoadingProgress = progress
            }
            }
        }
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
