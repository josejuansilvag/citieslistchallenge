//
//  CityDetailView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import MapKit // For the small map preview

struct CityDetailView: View {
    @State var viewModel: CityDetailViewModel
    @State private var mapRegion: MKCoordinateRegion

    /// Initialize mapRegion based on the city's coordinates
    init(city: City) {
        let detailViewModel = CityDetailViewModel(city: city)
        _viewModel = State(initialValue: detailViewModel)
        
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: city.coord_lat, longitude: city.coord_lon),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // Zoom level
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.city.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: "location.fill")
                    Text(viewModel.city.coordinatesString)
                }
                .font(.subheadline)
                .foregroundColor(.gray)

                /// Small Map Preview
                Map(initialPosition: .region(mapRegion)) {
                    Marker(viewModel.city.name, coordinate: CLLocationCoordinate2D(latitude: viewModel.city.coord_lat, longitude: viewModel.city.coord_lon))
                }
                .mapStyle(.standard)
                .frame(height: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                
                /// Favorite Status (Read-only display, toggle is on the list view)
                HStack {
                    Image(systemName: viewModel.city.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.city.isFavorite ? .red : .gray)
                    Text(viewModel.city.isFavorite ? "Favorite" : "Not a Favorite")
                }
               
                Section(header: Text("Raw Data").font(.title2)) {
                    InfoRow(label: "City ID", value: "\(viewModel.city.id)")
                    InfoRow(label: "Name", value: viewModel.city.name)
                    InfoRow(label: "Country Code", value: viewModel.city.country)
                    InfoRow(label: "Latitude", value: String(format: "%.6f", viewModel.city.coord_lat))
                    InfoRow(label: "Longitude", value: String(format: "%.6f", viewModel.city.coord_lon))
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.semibold)
            Text(value)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}



#Preview {
    let previewCity = City(id: 5435, name: "Morelia", country: "MX", coord_lon: 101.5, coord_lat: 19.7, isFavorite: true)
    return NavigationView {
        CityDetailView(city: previewCity)
    }
}
