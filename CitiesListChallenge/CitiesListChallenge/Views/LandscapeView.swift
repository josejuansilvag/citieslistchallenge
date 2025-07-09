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
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CityListViewModel
    
    @Binding var selectedCityForLandscapeMap: City?
    @State private var showingCityDetail: City? = nil
    
    init(selectedCityForLandscapeMap: Binding<City?>) {
        self._selectedCityForLandscapeMap = selectedCityForLandscapeMap
        let dataStore = DataStore(modelContext: ModelContext(try! ModelContainer(for: City.self)))
        _viewModel = State(wrappedValue: CityListViewModel(dataStore: dataStore))
    }
    
    var body: some View {
        NavigationView {
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search cities...", text: $viewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    Toggle("Show Favorites Only", isOn: $viewModel.showOnlyFavorites)
                        .padding(.horizontal)
                    List {
                        ForEach(viewModel.cities) { city in
                            CityRowView(
                                city: city,
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(forCityID: city.id)
                                }, onRowTap: {
                                    showingCityDetail = city
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
                    .listStyle(PlainListStyle())
                }
                .frame(minWidth: 300, maxWidth: 400)
                
                if let selectedCity = selectedCityForLandscapeMap {
                    MapView(city: selectedCity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Select a city to see it on the map.")
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Cities")
            .task {
                await viewModel.loadInitialDataIfNeeded()
            }
            .sheet(item: $showingCityDetail) { city in
                NavigationView {
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
                LandscapeView(selectedCityForLandscapeMap: $previewSelectedCity)
                    .modelContainer(for: City.self, inMemory: true)
            }
        }
        return PreviewWrapper()
    }
}
