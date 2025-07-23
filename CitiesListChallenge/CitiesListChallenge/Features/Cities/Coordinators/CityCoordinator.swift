//
//  CityCoordinator.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import SwiftUI
//TODO: - implementar este coordinator en la app, si esta crece encomplejidad se pueden crer coordinators especificos tambien
/// 🎯 CityCoordinator - Maneja la navegación específica de la feature Cities
///
/// Este coordinator es responsable de:
/// - Navegación entre vistas de Cities
/// - Presentación de sheets y full screens relacionados con Cities
/// - Coordinación con el MainCoordinator para navegación global
@MainActor
final class CityCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Ruta de navegación específica para Cities
    @Published var navigationPath = NavigationPath()
    
    /// Sheet actualmente presentado
    @Published var presentedSheet: CitySheetRoute?
    
    /// Full screen actualmente presentado
    @Published var presentedFullScreen: CityFullScreenRoute?
    
    // MARK: - Dependencies
    
    private let diContainer: DIContainerProtocol
    private let mainCoordinator: MainCoordinator
    
    // MARK: - Initialization
    
    init(diContainer: DIContainerProtocol, mainCoordinator: MainCoordinator) {
        self.diContainer = diContainer
        self.mainCoordinator = mainCoordinator
    }
    
    // MARK: - Navigation Methods
    
    /// Navega a la lista de ciudades
    func showCityList() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    /// Navega al detalle de una ciudad
    func showCityDetail(_ city: City) {
        navigationPath.append(CityNavigationRoute.cityDetail(city))
    }
    
    /// Presenta el mapa de una ciudad como sheet
    func showCityMap(_ city: City) {
        presentedSheet = .mapView(city)
    }
    
    /// Presenta el mapa de una ciudad como full screen
    func showCityMapFullScreen(_ city: City) {
        presentedFullScreen = .mapView(city)
    }
    
    /// Presenta la vista de landscape para una ciudad
    func showCityLandscape(_ city: City) {
        presentedFullScreen = .landscapeView(city)
    }
    
    /// Cierra el sheet actual
    func dismissSheet() {
        presentedSheet = nil
    }
    
    /// Cierra el full screen actual
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    /// Navega hacia atrás
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// Navega a la raíz
    func goToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    // MARK: - View Creation
    
    /// Crea la vista principal de la lista de ciudades
    func makeCityListView() -> CityListView {
        let viewModel = diContainer.makeCityListViewModel()
        return CityListView(viewModel: viewModel, coordinator: mainCoordinator)
    }
    
    /// Crea la vista de detalle de una ciudad
    func makeCityDetailView(for city: City) -> CityDetailView {
        let viewModel = diContainer.makeCityDetailViewModel(for: city)
        return CityDetailView(viewModel: viewModel)
    }
    
    /// Crea la vista de fila de ciudad
    func makeCityRowView(for city: City, onFavoriteToggle: @escaping () -> Void, onShowDetailToggle: @escaping () -> Void) -> CityRowView {
        return CityRowView(
            city: city,
            onFavoriteToggle: onFavoriteToggle,
            onShowDetailToggle: onShowDetailToggle
        )
    }
    
    /// Crea la vista de mapa
    func makeMapView(for city: City) -> MapView {
        return MapView(city: city)
    }
    
    /// Crea la vista de landscape
    func makeLandscapeView(viewModel: CityListViewModel, selectedCityForLandscapeMap: Binding<City?>) -> LandscapeView {
        return LandscapeView(
            viewModel: viewModel,
            selectedCityForLandscapeMap: selectedCityForLandscapeMap,
            coordinator: mainCoordinator
        )
    }
}

// MARK: - Navigation Routes

/// Rutas de navegación específicas para la feature Cities
enum CityNavigationRoute: Hashable {
    case cityDetail(City)
}

/// Rutas de sheets específicas para la feature Cities
enum CitySheetRoute: Identifiable {
    case mapView(City)
    
    var id: String {
        switch self {
        case .mapView(let city):
            return "mapView_\(city.id)"
        }
    }
}

/// Rutas de full screen específicas para la feature Cities
enum CityFullScreenRoute: Identifiable {
    case mapView(City)
    case landscapeView(City)
    
    var id: String {
        switch self {
        case .mapView(let city):
            return "mapViewFull_\(city.id)"
        case .landscapeView(let city):
            return "landscapeView_\(city.id)"
        }
    }
}
