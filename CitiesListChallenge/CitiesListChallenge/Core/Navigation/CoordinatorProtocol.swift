//
//  CoordinatorProtocol.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import SwiftUI
import Combine

// MARK: - Base Coordinator Protocol
/// Protocolo base para todos los coordinators en la app
@MainActor
protocol CoordinatorProtocol {
    var navigationPath: NavigationPath { get set }
    var presentedSheet: SheetRoute? { get set }
    var presentedFullScreen: FullScreenRoute? { get set }
    
    func showCityDetail(_ city: City)
    func showMapView(_ city: City)
    func dismissSheet()
    func dismissFullScreen()
}

// MARK: - Observable Coordinator Protocol
/// Protocolo que combina CoordinatorProtocol con ObservableObject
/// Para coordinators que necesitan ser observables en SwiftUI
@MainActor
protocol ObservableCoordinatorProtocol: CoordinatorProtocol, ObservableObject {}

// MARK: - ViewModel Factory Protocol
/// Protocolo para crear ViewModels d
@MainActor
protocol ViewModelFactory {
    func makeCityListViewModel() -> CityListViewModel
    func makeCityDetailViewModel(for city: City) -> CityDetailViewModel
    
    // MARK: - para demostrar como se puede extender la app
    // Para futuras expansiones, agregar aquí:
    // func makeSettingsViewModel() -> SettingsViewModel
 }

// MARK: - DIContainer Protocol
/// Protocolo para el contenedor de dependencias
/// Permite diferentes implementaciones (real, mock, testing)
@MainActor
protocol DIContainerProtocol {
    func makeCityListViewModel() -> CityListViewModel
    func makeCityDetailViewModel(for city: City) -> CityDetailViewModel
    func makeDataStore() -> DataStoreProtocol
    
    // MARK: - Tambien para demostrar como puedo extender la app posteriormente
    // Para futuras expansiones, agregar aquí:
    // func makeSettingsService() -> SettingsServiceProtocol
}

// MARK: - App Feature Enum
/// Enum que define todas las features de la app
enum AppFeature {
    case cities
    
    //Estos son solo para ejemplificar futuras expansiones de la appp
    case settings
    case auth
    case profile

}
