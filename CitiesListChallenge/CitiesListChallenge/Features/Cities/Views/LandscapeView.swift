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
    @ObservedObject var coordinator: MainCoordinator
    
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
                                    coordinator.showCityDetail(city)
                                }
                            )
                            .padding(.vertical, 12)
                            .padding(.trailing, 12)
                            .listRowInsets(EdgeInsets())
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCityForLandscapeMap = city
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
            .sheet(item: $coordinator.presentedSheet) { sheetRoute in
                coordinator.view(for: sheetRoute)
            }
            .fullScreenCover(item: $coordinator.presentedFullScreen) { fullScreenRoute in
                NavigationStack {
                    coordinator.view(for: fullScreenRoute)
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
                let diContainer = DIContainer(modelContainer: try! ModelContainer(for: City.self), useMockData: true)
                let mainCoordinator = MainCoordinator(diContainer: diContainer)
                let viewModel = mainCoordinator.makeCityListViewModel()
                
                LandscapeView(
                    viewModel: viewModel,
                    selectedCityForLandscapeMap: $previewSelectedCity,
                    coordinator: mainCoordinator
                )
                .modelContainer(for: City.self, inMemory: true)
            }
        }
        return PreviewWrapper()
    }
}
