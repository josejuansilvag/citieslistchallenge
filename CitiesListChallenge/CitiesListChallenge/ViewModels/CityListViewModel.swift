//
//  CityListViewModel.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation
import SwiftData
import Combine

@Observable @MainActor
class CityListViewModel {
    private let dataStore: DataStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var searchText: String = "" {
        didSet {
            searchTextSubject.send(searchText)
        }
    }
    
    var showOnlyFavorites: Bool = false {
        didSet {
            showOnlyFavoritesSubject.send(showOnlyFavorites)
        }
    }
    
    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    private let showOnlyFavoritesSubject = CurrentValueSubject<Bool, Never>(false)
    
    var cities: [City] = []
    var isLoading = false
    var errorMessage: String?
    var hasMorePages = true
    
    private let pageSize = 50
    private var currentPage = 0
    private var hasInitialized = false
    
    init(dataStore: DataStoreProtocol) {
        self.dataStore = dataStore
        setupSearchSubscription()
    }
    
    private func setupSearchSubscription() {
        Publishers.CombineLatest(searchTextSubject, showOnlyFavoritesSubject)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates { prev, curr in
                prev.0 == curr.0 && prev.1 == curr.1
            }
            .sink { [weak self] searchText, showOnlyFavorites in
                 self?.resetAndLoadFirstPage()
            }
            .store(in: &cancellables)
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
