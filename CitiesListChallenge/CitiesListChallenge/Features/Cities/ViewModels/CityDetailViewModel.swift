//
//  CityDetailViewModel.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI

@Observable
class CityDetailViewModel {
    let city: City
    
    // MARK: - Weather Data
    var weatherInfo: WeatherInfo?
    var isLoadingWeather = false
    var weatherError: String?
    
    // MARK: - Services
    private let networkService: NetworkServiceProtocol
    
    init(city: City, 
         networkService: NetworkServiceProtocol = NetworkService()) {
        self.city = city
        self.networkService = networkService
        Task {
            await fetchWeatherData()
        }
    }
    
    @MainActor
    func fetchWeatherData() async {
        isLoadingWeather = true
        weatherError = nil
        
        do {
            weatherInfo = try await networkService.getWeather(lat: city.coord_lat, lon: city.coord_lon)
        } catch {
            weatherError = "Unable to load weather data"
            print("Weather error: \(error)")
        }
        
        isLoadingWeather = false
    }
    
    // MARK: - Computed Properties
    var weatherIconURL: URL? {
        guard let icon = weatherInfo?.icon else { return nil }
        return URL(string: "https://\(icon)")
    }
    
    var temperatureString: String {
        guard let temp = weatherInfo?.temperature else { return "N/A" }
        return String(format: "%.1f°C", temp)
    }
    
    var feelsLikeString: String {
        guard let feelsLike = weatherInfo?.feelsLike else { return "N/A" }
        return String(format: "%.1f°C", feelsLike)
    }
    
    var humidityString: String {
        guard let humidity = weatherInfo?.humidity else { return "N/A" }
        return "\(humidity)%"
    }
    
    var pressureString: String {
        guard let pressure = weatherInfo?.pressure else { return "N/A" }
        return String(format: "%0f hPa", pressure)
    }
    
    var windSpeedString: String {
        guard let windSpeed = weatherInfo?.windSpeed else { return "N/A" }
        return String(format: "%.1f km/h", windSpeed)
    }
    
    var uvString: String {
        guard let uv = weatherInfo?.uv else { return "N/A" }
        return String(format: "%.1f", uv)
    }
    
    var visibilityString: String {
        guard let visibility = weatherInfo?.visibility else { return "N/A" }
        return String(format: "%.1f km", visibility)
    }
    
    var weatherDescription: String {
        weatherInfo?.description.capitalized ?? "Weather data unavailable"
    }
}
