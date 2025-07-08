//
//  CityListViewModel.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class CityListViewModel: ObservableObject {
    private let dataStore: DataStore
    private var cancellables = Set<AnyCancellable>()
    
    @Published var searchText = ""
    @Published var showOnlyFavorites = false
    @Published var cities: [City] = []
    @Published var totalCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true
    
    private let pageSize = 50
    private var currentPage = 0
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        setupSearchSubscription()
    }
    
    private func setupSearchSubscription() {
        Publishers.CombineLatest($searchText, $showOnlyFavorites)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates { prev, curr in
                prev.0 == curr.0 && prev.1 == curr.1
            }
            .sink { [weak self] searchText, showOnlyFavorites in
                print("Search text: \(searchText), Show only favorites: \(showOnlyFavorites)")
                self?.resetAndLoadFirstPage()
            }
            .store(in: &cancellables)
    }
    
    func resetAndLoadFirstPage() {
        currentPage = 0
        hasMorePages = true
        loadNextPage()
    }
    
    func loadNextPage() {
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        print("Loading with showOnlyFavorites: \(showOnlyFavorites)")
        let result = dataStore.searchCities(
            prefix: searchText,
            onlyFavorites: showOnlyFavorites,
            page: currentPage,
            pageSize: pageSize
        )
        
        cities = currentPage == 0 ? result.cities : cities + result.cities
        totalCount = result.totalMatchingCount
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
    
    func prepareDataStore() async {
        await dataStore.prepareDataStore()
    }
}
