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
    let onRowTap: () -> Void
    
    var body: some View {
        HStack {
            HStack{
                VStack(alignment: .leading) {
                    Text(city.name)
                        .font(.headline)
                    Text(city.country)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTap()
            }
            Button {
                onShowDetailToggle()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            Button {
                print("favourite button tapped")
                onFavoriteToggle()
            } label: {
                Image(systemName: city.isFavorite ? "star.fill" : "star")
                    .foregroundColor(city.isFavorite ? .yellow : .gray)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(city.isFavorite ? "star.fill" : "star")
            
        }
    }
}

#Preview {
    let sampleCity1 = City(id: 1, name: "Morelia", country: "MX", coord_lon: -74.0060, coord_lat: 40.7128, isFavorite: true)
    let sampleCity2 = City(id: 2, name: "Buenos Aires", country: "AR", coord_lon: 100.2093, coord_lat: -38.8688, isFavorite: false)
    
    VStack {
        CityRowView(city: sampleCity1, onFavoriteToggle: { print("Toggled Fav 1") }, onShowDetailToggle: {}, onRowTap: { print("Row 1 tapped") })
        CityRowView(city: sampleCity2, onFavoriteToggle: { print("Toggled Fav 2") }, onShowDetailToggle: {}, onRowTap: { print("Row 2 tapped") })
    }
    .padding()
}
