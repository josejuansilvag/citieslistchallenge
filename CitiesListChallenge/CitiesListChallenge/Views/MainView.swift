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
    
    @State private var selectedCityForLandscapeMap: City? = nil
    @State private var cityListViewModel: CityListViewModel?
    
    // Detectar si debemos usar mock data
    private var useMockData: Bool {
        ProcessInfo.processInfo.arguments.contains("--useMockDataForUITesting")
    }
    
    var body: some View {
        Group {
            if let viewModel = cityListViewModel {
                if verticalSizeClass == .regular && horizontalSizeClass == .compact {
                    CityListView(viewModel: viewModel)  //view for portrait
                } else {
                    LandscapeView(
                        viewModel: viewModel,
                        selectedCityForLandscapeMap: $selectedCityForLandscapeMap
                    )
                }
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if cityListViewModel == nil {
                await createDIContainerAndViewModel()
            }
        }
    }
    
    @MainActor
    private func createDIContainerAndViewModel() async {
        print("MainView: useMockData = \(useMockData)")
        let diContainer = DIContainer(modelContainer: modelContext.container, useMockData: useMockData)
        cityListViewModel = diContainer.makeCityListViewModel()
        print("MainView: ViewModel creado con DIContainer")
        
        // Preparar el data store (solo para datos reales, no para mocks)
        if !useMockData {
            print("MainView: Preparando data store para datos reales")
            let dataStore = diContainer.makeDataStore()
            await dataStore.prepareDataStore()
        }
    }
}

#Preview("MainView - Portrait") {
    MainView()
        .modelContainer(for: City.self, inMemory: true)
        .environment(\.horizontalSizeClass, .compact)
        .environment(\.verticalSizeClass, .regular)
}

#Preview("MainView - Landscape") {
    MainView()
        .modelContainer(for: City.self, inMemory: true)
        .environment(\.horizontalSizeClass, .regular) 
        .environment(\.verticalSizeClass, .compact)
}
