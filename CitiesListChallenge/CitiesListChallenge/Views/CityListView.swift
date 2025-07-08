
//
//  Untitled.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import SwiftData

struct CityListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CityListViewModel
    
    @State private var selectedCityForMap: City? = nil
    @State private var showingCityDetail: City? = nil
    
    init() {
        let dataStore = DataStore(modelContext: ModelContext(try! ModelContainer(for: City.self)))
        _viewModel = StateObject(wrappedValue: CityListViewModel(dataStore: dataStore))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Toggle("Show Favorites Only", isOn: $viewModel.showOnlyFavorites)
                    .padding(.horizontal)
                
                // City list
                List{
                    ForEach(viewModel.cities) { city in
                        CityRowView(
                            city: city,
                            onFavoriteToggle: {
                                viewModel.toggleFavorite(forCityID: city.id)
                            },
                            onRowTap: {
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
                .listStyle(.plain)
                
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle("Cities")
            
            .task {
                await viewModel.prepareDataStore()
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

struct CityListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CityListView()
                .modelContainer(for: City.self, inMemory: true)
        }
    }
}
