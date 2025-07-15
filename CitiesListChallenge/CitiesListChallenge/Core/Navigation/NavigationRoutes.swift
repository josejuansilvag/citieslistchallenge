//
//  NavigationRoutes.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import SwiftUI

// MARK: - Navigation Routes
/// Enum que define todas las rutas de navegación en la app
enum NavigationRoute: Hashable {
    case cityList
    case cityDetail(City)
    case mapView(City)
}

// MARK: - Sheet Routes
/// Enum que define todas las rutas de sheets en la app
enum SheetRoute: Identifiable {
    case cityDetail(City)
    
    var id: String {
        switch self {
        case .cityDetail(let city):
            return "cityDetail-\(city.id)"
        }
    }
}

// MARK: - Full Screen Cover Routes
/// Enum que define todas las rutas de full screen covers en la app
enum FullScreenRoute: Identifiable {
    case mapView(City)
    
    var id: String {
        switch self {
        case .mapView(let city):
            return "mapView-\(city.id)"
        }
    }
}
