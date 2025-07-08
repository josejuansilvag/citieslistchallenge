//
//  NetworkService.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation

//TODO: - Create appropiate protocols, for the mvp i will use this simple class
class NetworkService {
    // URL for the city data
    private let citiesURL = URL(string: "https://gist.githubusercontent.com/hernan-uala/dce8843a8edbe0b0018b32e137bc2b3a/raw/0996accf70cb0ca0e16f9a99e0ee185fafca7af1/cities.json")!

    enum NetworkError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError(Error)
    }

    func downloadCityData() async throws -> [CityJSON] {
        let (data, response) = try await URLSession.shared.data(from: citiesURL)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let cities = try decoder.decode([CityJSON].self, from: data)
            return cities
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
