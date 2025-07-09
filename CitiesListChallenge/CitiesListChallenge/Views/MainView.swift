//
//  MainView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var selectedCityForLandscapeMap: City? = nil

    var body: some View {
        if verticalSizeClass == .regular && horizontalSizeClass == .compact {
           PortraitView()
        } else {
            LandscapeView(selectedCityForLandscapeMap: $selectedCityForLandscapeMap)
        }
    }
}

struct PortraitView: View {
    var body: some View {
        CityListView()
    }
}

struct PortraitMainView: View {
    var body: some View {
        Text("Portrait Layout - List and Map will be separate")
    }
}

struct LandscapeMainView: View {
    var body: some View {
        Text("Landscape Layout - List and Map will be combined")
    }
}

// Preview for MainView
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
