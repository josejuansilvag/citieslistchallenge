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
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    Toggle("Show Favorites Only", isOn: $viewModel.showOnlyFavorites)
                        .accessibilityIdentifier("favoritesToggle")
                        .padding(.horizontal)
                        .padding(.top, 8)
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
                            .padding(.vertical, 12)
                            .padding(.trailing, 12)
                            .listRowInsets(EdgeInsets())
                            .contentShape(Rectangle())
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
                    .padding(.leading, -40)
                }
                .frame(width: 320)
                .searchable(text: $viewModel.searchText)
                .navigationTitle("Cities")
                Group {
                    if let selectedCity = selectedCityForLandscapeMap {
                        MapView(city: selectedCity)
                            .cornerRadius(12)
                    } else {
                        Text("Select a city to view on map")
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(8)
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
                    viewModel: CityListViewModel(dataStore: DataStore(
                        repository: CityRepository(modelContext: ModelContext(try! ModelContainer(for: City.self))),
                        networkService: NetworkService()
                    )),
                    selectedCityForLandscapeMap: $previewSelectedCity
                )
                .modelContainer(for: City.self, inMemory: true)
            }
        }
        return PreviewWrapper()
    }
}
