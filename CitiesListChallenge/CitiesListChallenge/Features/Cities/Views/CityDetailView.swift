//
//  CityDetailView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI
import MapKit

struct CityDetailView: View {
    @State var viewModel: CityDetailViewModel
    @State private var mapRegion: MKCoordinateRegion

    init(city: City) {
        let detailViewModel = CityDetailViewModel(city: city)
        _viewModel = State(initialValue: detailViewModel)
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: city.coord_lat, longitude: city.coord_lon),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.city.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    HStack {
                        Image(systemName: "location.fill")
                        Text(viewModel.city.coordinatesString)
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                // MARK: - Weather Section
                WeatherSection(viewModel: viewModel)
                // MARK: - Map Preview
                Map(initialPosition: .region(mapRegion)) {
                    Marker(viewModel.city.name, coordinate: CLLocationCoordinate2D(latitude: viewModel.city.coord_lat, longitude: viewModel.city.coord_lon))
                }
                .mapStyle(.standard)
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
  
                // MARK: - Favorite Status
                HStack {
                    Image(systemName: viewModel.city.isFavorite ? "star.fill" : "star")
                        .foregroundColor(viewModel.city.isFavorite ? .yellow : .gray)
                    Text(viewModel.city.isFavorite ? "Favorite" : "Not a Favorite")
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
                // MARK: - Technical Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("City Details")
                        .font(.title2)
                        .fontWeight(.semibold)
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

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let previewCity = City(id: 5435, name: "Morelia", country: "MX", coord_lon: 101.5, coord_lat: 19.7, isFavorite: true)
    return NavigationView {
        CityDetailView(city: previewCity)
    }
} 
