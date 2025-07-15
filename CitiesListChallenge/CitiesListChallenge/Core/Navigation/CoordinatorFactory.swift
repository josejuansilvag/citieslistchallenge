//
//  CoordinatorFactory.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 14/07/25.
//

import SwiftUI

// MARK: - Coordinator Factory
/// Factory para crear coordinators de forma consistente
@MainActor
final class CoordinatorFactory {
    private let diContainer: DIContainerProtocol
    
    init(diContainer: DIContainerProtocol) {
        self.diContainer = diContainer
    }
    
    // MARK: - Main Coordinators
    
    /// Crea el coordinator principal de la app
    func makeMainCoordinator() -> MainCoordinator {
        return MainCoordinator(diContainer: diContainer)
    }
    
    /// Crea un coordinator mock para testing
    func makeMockCoordinator() -> MockCoordinator {
        return MockCoordinator()
    }
    
    // MARK: - Feature-Specific Coordinators
    
    /// Crea un coordinator específico para el flujo de ciudades
    /// Por ahora usa MainCoordinator, pero puede ser reemplazado por CityFlowCoordinator en el futuro
    func makeCityFlowCoordinator() -> MainCoordinator {
        return MainCoordinator(diContainer: diContainer)
    }
    
    // MARK: - Coordinator Creation forspecific features
    
    /// Crea un coordinator basado en la feature especificada, por ahora solo tnecesitamos uno pero la idea es demostrar como podriamos expandir la app
    func makeCoordinator(for feature: AppFeature) -> MainCoordinator {
        switch feature {
        case .cities:
            return makeCityFlowCoordinator()
        case .settings, .auth, .profile:
            // TODO: Implement specific coordinators for these features
            return makeMainCoordinator()
        }
    }
}
