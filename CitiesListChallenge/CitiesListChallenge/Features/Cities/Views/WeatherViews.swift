//
//  WeatherViews.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI

// MARK: - Weather Section
struct WeatherSection: View {
    let viewModel: CityDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
                Text("Current Weather")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if viewModel.isLoadingWeather {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading weather...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else if let error = viewModel.weatherError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else if viewModel.weatherInfo != nil {
                VStack(alignment: .leading, spacing: 12) {
                    // Main weather info
                    HStack {
                        if let iconURL = viewModel.weatherIconURL {
                            AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                            } placeholder: {
                                Image(systemName: "cloud")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.temperatureString)
                                .font(.title)
                                .fontWeight(.bold)
                            Text(viewModel.weatherDescription)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // Detailed weather info grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        WeatherInfoItem(icon: "thermometer", label: "Feels Like", value: viewModel.feelsLikeString)
                        WeatherInfoItem(icon: "humidity", label: "Humidity", value: viewModel.humidityString)
                        WeatherInfoItem(icon: "wind", label: "Wind Speed", value: viewModel.windSpeedString)
                        WeatherInfoItem(icon: "gauge", label: "Pressure", value: viewModel.pressureString)
                        WeatherInfoItem(icon: "sun.max", label: "UV Index", value: viewModel.uvString)
                        WeatherInfoItem(icon: "eye", label: "Visibility", value: viewModel.visibilityString)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Weather Info Item
struct WeatherInfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

//#Preview("Weather Section") {
//    let mockViewModel = CityDetailViewModel(city: City(id: 1, name: "London", country: "GB", coord_lon: -0.1276, coord_lat: 51.5074, isFavorite: false))
//    mockViewModel.weatherInfo = WeatherInfo(
//        location: Location(name: "London", region: "England", country: "GB", lat: 51.574, lon: -0.1276, localtime: "2024-07-07 10:00"),
//        current: CurrentWeather(
//            temp_c: 22,
//            feelslike_c: 24,
//            humidity: 65,
//            pressure_mb: 113,
//            wind_kph: 15,
//            wind_degree: 180,
//            uv: 5.0,
//            vis_km: 10,
//            condition: WeatherCondition(text: "Partly cloudy", icon: "https://cdn.weatherapi.com/weather/64x64/116.png", code: 13)
//        )
//    )
//    
//    WeatherSection(viewModel: mockViewModel)
//        .padding()
//}
//
