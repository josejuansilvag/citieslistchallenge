
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
    @ObservedObject var coordinator: MainCoordinator
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack {
            Toggle("Show Favorites Only", isOn: $viewModel.showOnlyFavorites)
                .accessibilityIdentifier("favoritesToggle")
                .padding(.horizontal)
            
            List{
                ForEach(viewModel.cities) { city in
                    NavigationLink(value: NavigationRoute.mapView(city)) {
                        CityRowView(
                            city: city,
                            onFavoriteToggle: {
                                viewModel.toggleFavorite(forCityID: city.id)
                            }, onShowDetailToggle: {
                                coordinator.showCityDetail(city)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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
        .navigationDestination(for: NavigationRoute.self) { route in
            coordinator.view(for: route)
        }
    }
}

struct CityListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let diContainer = DIContainer(modelContainer: try! ModelContainer(for: City.self), useMockData: true)
            let mainCoordinator = MainCoordinator(diContainer: diContainer)
            let viewModel = mainCoordinator.makeCityListViewModel()
            
            CityListView(viewModel: viewModel, coordinator: mainCoordinator)
                .modelContainer(for: City.self, inMemory: true)
        }
    }
}
