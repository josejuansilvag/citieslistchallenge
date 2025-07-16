//
//  CityRowView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI

struct CityRowView: View {
    let city: City
    let onFavoriteToggle: () -> Void
    let onShowDetailToggle: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(AppTheme.secondary)
                .background(
                    Circle()
                        .fill(AppTheme.background)
                        .frame(width: 40, height: 40)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.text)
                    .accessibilityIdentifier("city.name")
                Text(city.country)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("city.country")
            }
            Spacer()
            
            /// Botón de detalle
            Button(action: onShowDetailToggle) {
                Image(systemName: "info.circle")
                    .foregroundColor(AppTheme.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityIdentifier("info.circle")
            
            /// Botón de favorito
            Button(action: onFavoriteToggle) {
                Image(systemName: city.isFavorite ? "star.fill" : "star")
                    .foregroundColor(city.isFavorite ? AppTheme.accent : .gray)
                    .imageScale(.large)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(city.isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityIdentifier("favorite.button")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cellBackground)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    let sampleCity1 = City(id: 1, name: "Morelia", country: "MX", coord_lon: -74.0060, coord_lat: 40.7128, isFavorite: true)
    let sampleCity2 = City(id: 2, name: "Buenos Aires", country: "AR", coord_lon: 100.2093, coord_lat: -38.8688, isFavorite: false)
    
    VStack {
        CityRowView(city: sampleCity1, onFavoriteToggle: { print("Toggled Fav 1") }, onShowDetailToggle: { print("Show detail 1") })
        CityRowView(city: sampleCity2, onFavoriteToggle: { print("Toggled Fav 2") }, onShowDetailToggle: { print("Show detail 2") })
    }
    .padding()
}
