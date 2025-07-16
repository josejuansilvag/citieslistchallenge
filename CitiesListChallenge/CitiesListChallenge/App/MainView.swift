//
//  MainView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var coordinator: MainCoordinator
    @State private var selectedCityForLandscapeMap: City? = nil
    @State private var cityListViewModel: CityListViewModel?
    
    init() {
        let modelContainer = try! ModelContainer(for: City.self)
        let useMockData = ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting")
        let diContainer = DIContainer(modelContainer: modelContainer, useMockData: useMockData)
        let factory = CoordinatorFactory(diContainer: diContainer)
        _coordinator = StateObject(wrappedValue: factory.makeMainCoordinator())
    }
    
    private var useMockData: Bool {
        ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting")
    }
    
    var body: some View {
        Group {
            if let viewModel = cityListViewModel {
                if verticalSizeClass == .regular && horizontalSizeClass == .compact {
                    NavigationStack(path: $coordinator.navigationPath) {
                        CityListView(viewModel: viewModel, coordinator: coordinator)
                    }
                    .sheet(item: $coordinator.presentedSheet) { sheetRoute in
                        coordinator.view(for: sheetRoute)
                    }
                    .fullScreenCover(item: $coordinator.presentedFullScreen) { fullScreenRoute in
                        NavigationStack {
                            coordinator.view(for: fullScreenRoute)
                        }
                    }
                } else {
                    LandscapeView(
                        viewModel: viewModel,
                        selectedCityForLandscapeMap: $selectedCityForLandscapeMap,
                        coordinator: coordinator
                    )
                }
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await createViewModelIfNeeded()
        }
    }
    
    @MainActor
    private func createViewModelIfNeeded() async {
        guard cityListViewModel == nil else { return }
        cityListViewModel = coordinator.makeCityListViewModel()
        // Always prepare data store, whether using mock or real data
        let dataStore = coordinator.getDIContainer().makeDataStore()
        await dataStore.prepareDataStore()
    }
}

