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
    @State private var region: MKCoordinateRegion
    struct AnnotatedItem: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    private var annotatedItem: [AnnotatedItem]

    init(city: City) {
        self.city = city
        let coordinate = CLLocationCoordinate2D(latitude: city.coord_lat, longitude: city.coord_lon)
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Adjust span for desired zoom
        ))
        self.annotatedItem = [
            AnnotatedItem(name: city.name, coordinate: coordinate)
        ]
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotatedItem) { item in
            MapMarker(coordinate: item.coordinate, tint: .blue)
        }
        .onAppear {
            let coordinate = CLLocationCoordinate2D(latitude: city.coord_lat, longitude: city.coord_lon)
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

#Preview {
    let previewCity = City(id: 1, name: "Morelai", country: "MX", coord_lon: -100.0, coord_lat: 37.8, isFavorite: false)
    
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
