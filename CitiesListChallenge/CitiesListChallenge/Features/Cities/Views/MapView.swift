//
//  MapView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    let city: City
    
    struct AnnotatedItem: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
    
    private var annotatedItem: AnnotatedItem {
        AnnotatedItem(
            name: city.name,
            coordinate: CLLocationCoordinate2D(latitude: city.coord_lat, longitude: city.coord_lon)
        )
    }
    
    var body: some View {
        Map(initialPosition: .region(initialRegion)) {
            Marker(annotatedItem.name, coordinate: annotatedItem.coordinate)
        }
        .mapStyle(.standard)
        .navigationTitle(city.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var initialRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: annotatedItem.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

#Preview {
    let previewCity = City(id: 1, name: "Cupertino", country: "US", coord_lon: -122.0321823, coord_lat: 37.3229978, isFavorite: false)
    return NavigationView {
        MapView(city: previewCity)
            .navigationTitle("Map: \(previewCity.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        print("Done button tapped in preview")
                    }
                }
            }
    }
}
