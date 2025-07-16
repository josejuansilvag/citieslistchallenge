//
//  Theme.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 10/07/25.
//

import SwiftUI

struct AppTheme {
    // Colores del sistema para que funcionen inmediatamente
    static let primary = Color("CitiesBlue")
    static let secondary = Color("CitiesYellow")
    static let background = Color("Background")
    static let cellBackground = Color.white
    static let text = Color("Text")
    static let accent = Color("Accent")
    
    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let bodyFont = Font.system(.body, design: .rounded)
}
