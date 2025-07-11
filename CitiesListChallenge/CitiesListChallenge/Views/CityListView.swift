
//
//  Untitled.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import SwiftData

struct CityListView: View {
    @Bindable var viewModel: CityListViewModel
    
    @State private var selectedCityForMap: City? = nil
    @State private var showingCityDetail: City? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            VStack {
                // Favorites toggle
                Toggle("Show Favorites Only", isOn: $viewModel.showOnlyFavorites)
                    .accessibilityIdentifier("favoritesToggle")
                    .padding(.horizontal)
                
                // City list
                List{
                    ForEach(viewModel.cities) { city in
                        NavigationLink(destination: CityDetailView(city: city)) {
                            CityRowView(
                                city: city,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(forCityID: city.id)
                                }, onShowDetailToggle: {
                                    showingCityDetail = city
                                },
                                onRowTap: {
                                    selectedCityForMap = city
                                }
                            )
                        }
                    }
                    if viewModel.hasMorePages {
                        ProgressView()
                            .onAppear {
                                Task {
                                    await viewModel.loadNextPage()
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, horizontalSizeClass == .regular ? -20 : 0)
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle("Cities")
            .task {
                await viewModel.loadInitialDataIfNeeded()
             }
            .navigationDestination(item: $selectedCityForMap, destination: { city in
                MapView(city: city)
            })
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

struct CityListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CityListView(viewModel: CityListViewModel(dataStore: DataStore(
                repository: CityRepository(modelContext: ModelContext(try! ModelContainer(for: City.self))),
                networkService: NetworkService()
            )))
                .modelContainer(for: City.self, inMemory: true)
        }
    }
}
