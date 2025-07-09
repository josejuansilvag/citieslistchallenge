//
//  LandscapeView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import MapKit
import SwiftData

struct LandscapeView: View {
    @State var viewModel: CityListViewModel
    
    @Binding var selectedCityForLandscapeMap: City?
    @State private var showingCityDetail: City? = nil
    
    var body: some View {
        NavigationView {
            HStack {
                // Left side: City list
                VStack {
                    // Favorites toggle
                    Toggle("Show Favorites Only", isOn: $viewModel.showOnlyFavorites)
                        .padding(.horizontal)
                    
                    // City list
                    List {
                        ForEach(viewModel.cities) { city in
                            CityRowView(
                                city: city,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(forCityID: city.id)
                                },
                                onShowDetailToggle: {
                                    showingCityDetail = city
                                },
                                onRowTap: {
                                    selectedCityForLandscapeMap = city
                                }
                            )
                        }
                        
                        if viewModel.hasMorePages {
                            ProgressView()
                                .onAppear {
                                    viewModel.loadNextPage()
                                }
                        }
                    }
                    .listStyle(.plain)
                }
                .frame(width: 300)
                .searchable(text: $viewModel.searchText)
                .navigationTitle("Cities")
                
                // Right side: Map
                if let selectedCity = selectedCityForLandscapeMap {
                    MapView(city: selectedCity)
                } else {
                    Text("Select a city to view on map")
                        .foregroundColor(.gray)
                }
            }
            .task {
                await viewModel.loadInitialDataIfNeeded()
            }
            .sheet(item: $showingCityDetail) { city in
                NavigationStack {
                    CityDetailView(city: city)
                        .navigationTitle("Details: \(city.name)")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") { showingCityDetail = nil }
                            }
                        }
                }
            }
        }
    }
}

struct LandscapeView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var previewSelectedCity: City? = nil
            var body: some View {
                LandscapeView(
                    viewModel: CityListViewModel(dataStore: MockDataStore(repository: MockCityRepository(), networkService: MockNetworkService())),
                    selectedCityForLandscapeMap: $previewSelectedCity
                )
                    .modelContainer(for: City.self, inMemory: true)
            }
        }
        return PreviewWrapper()
    }
}
