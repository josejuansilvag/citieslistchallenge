//
//  MockCoordinator.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import SwiftUI
import Combine

// MARK: - Mock Coordinator for Testing
/// Coordinator mock para testing de la arquitectura
@MainActor
final class MockCoordinator: ObservableCoordinatorProtocol {
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: FullScreenRoute?
    
    // MARK: - Test Tracking Properties
    var showCityDetailCalled = false
    var showMapViewCalled = false
    var dismissSheetCalled = false
    var dismissFullScreenCalled = false
    
    var lastCityDetailShown: City?
    var lastMapViewShown: City?
    
    // MARK: - CoordinatorProtocol Implementation
    
    func showCityDetail(_ city: City) {
        showCityDetailCalled = true
        lastCityDetailShown = city
        presentedSheet = .cityDetail(city)
        print("🟡 MockCoordinator: showCityDetail called for \(city.name)")
    }
    
    func showMapView(_ city: City) {
        showMapViewCalled = true
        lastMapViewShown = city
        navigationPath.append(NavigationRoute.mapView(city))
        print("🟡 MockCoordinator: showMapView called for \(city.name)")
    }
    
    func dismissSheet() {
        dismissSheetCalled = true
        presentedSheet = nil
        print("🟡 MockCoordinator: dismissSheet called")
    }
    
    func dismissFullScreen() {
        dismissFullScreenCalled = true
        presentedFullScreen = nil
        print("🟡 MockCoordinator: dismissFullScreen called")
    }
    
    // MARK: - Test Helper Methods
    
    /// Resetea el estado del mock para nuevos tests
    func reset() {
        showCityDetailCalled = false
        showMapViewCalled = false
        dismissSheetCalled = false
        dismissFullScreenCalled = false
        lastCityDetailShown = nil
        lastMapViewShown = nil
        navigationPath = NavigationPath()
        presentedSheet = nil
        presentedFullScreen = nil
    }
    
    /// Verifica que se llamó showCityDetail con la ciudad correcta
    func verifyShowCityDetailCalled(for city: City) -> Bool {
        return showCityDetailCalled && lastCityDetailShown?.id == city.id
    }
    
    /// Verifica que se llamó showMapView con la ciudad correcta
    func verifyShowMapViewCalled(for city: City) -> Bool {
        return showMapViewCalled && lastMapViewShown?.id == city.id
    }
}
