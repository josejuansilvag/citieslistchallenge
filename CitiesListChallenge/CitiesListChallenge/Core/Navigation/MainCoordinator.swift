//
//  MainCoordinator.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import SwiftUI
import Combine
import MapKit

@MainActor
final class MainCoordinator: ObservableCoordinatorProtocol, ViewModelFactory {
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: FullScreenRoute?
    
    private let diContainer: DIContainerProtocol
    
    init(diContainer: DIContainerProtocol) {
        self.diContainer = diContainer
    }
    
    // MARK: - ViewModelFactory Implementation
    func makeCityListViewModel() -> CityListViewModel {
        return diContainer.makeCityListViewModel()
    }
    
    func makeCityDetailViewModel(for city: City) -> CityDetailViewModel {
        return diContainer.makeCityDetailViewModel(for: city)
    }
    
    // MARK: - CoordinatorProtocol Implementation
    func showCityDetail(_ city: City) {
        presentedSheet = .cityDetail(city)
    }
    
    func showMapView(_ city: City) {
        navigationPath.append(NavigationRoute.mapView(city))
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    // MARK: - View Creation
    @ViewBuilder
    func view(for route: NavigationRoute) -> some View {
        switch route {
        case .cityList:
            Text("City List")
        case .cityDetail(let city):
            let viewModel = makeCityDetailViewModel(for: city)
            CityDetailView(viewModel: viewModel)
        case .mapView(let city):
            MapView(city: city)
        }
    }
    
    @ViewBuilder
    func view(for sheetRoute: SheetRoute) -> some View {
        switch sheetRoute {
        case .cityDetail(let city):
            let viewModel = makeCityDetailViewModel(for: city)
            NavigationStack {
                CityDetailView(viewModel: viewModel)
                    .navigationTitle("Details: \(city.name)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { [weak self] in
                                self?.dismissSheet()
                            }
                        }
                    })
            }
        }
    }
    
    @ViewBuilder
    func view(for fullScreenRoute: FullScreenRoute) -> some View {
        switch fullScreenRoute {
        case .mapView(let city):
            MapView(city: city)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") { [weak self] in
                            self?.dismissFullScreen()
                        }
                    }
                })
        }
    }
    
    // MARK: - DIContainer Access
    func getDIContainer() -> DIContainerProtocol {
        return diContainer
    }
}
