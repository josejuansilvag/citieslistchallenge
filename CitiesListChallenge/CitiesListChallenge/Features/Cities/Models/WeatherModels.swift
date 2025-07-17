//
//  WeatherModels.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation

// MARK: - Weather Data Models (WeatherAPI.com)
struct WeatherInfo: Codable {
    let location: Location
    let current: CurrentWeather
    
    var temperature: Double { current.temp_c }
    var feelsLike: Double { current.feelslike_c }
    var humidity: Int { current.humidity }
    var pressure: Double { current.pressure_mb }
    var windSpeed: Double { current.wind_kph }
    var description: String { current.condition.text }
    var icon: String { current.condition.icon }
    var uv: Double { current.uv }
    var visibility: Double { current.vis_km }
    var cityName: String { location.name }
    var country: String { location.country }
}

struct Location: Codable {
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double
    let localtime: String
}

struct CurrentWeather: Codable {
    let temp_c: Double
    let feelslike_c: Double
    let humidity: Int
    let pressure_mb: Double
    let wind_kph: Double
    let wind_degree: Int
    let uv: Double
    let vis_km: Double
    let condition: WeatherCondition
}

struct WeatherCondition: Codable {
    let text: String
    let icon: String
    let code: Int
} 