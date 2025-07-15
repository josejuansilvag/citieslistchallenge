//
//  NetworkService.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import Foundation

// MARK: - Network Service Implementation
@MainActor
final class NetworkService: NetworkServiceProtocol {
    private let networkClient: NetworkClientProtocol
    
    init(networkClient: NetworkClientProtocol? = nil) {
        self.networkClient = networkClient ?? NetworkClient()
    }
    
    func downloadCityData() async throws -> [CityJSON] {
        return try await networkClient.request(.cities, parameters: nil)
    }
}

// MARK: - API Endpoints
enum APIEndpoint {
    case cities
    
    var path: String {
        switch self {
        case .cities:
            return "https://gist.githubusercontent.com/hernan-uala/dce8843a8edbe0b0018b32e137bc2b3a/raw/0996accf70cb0ca0e16f9a99e0ee185fafca7af1/cities.json"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .cities:
            return .GET
        }
    }
}




// MARK: - Network Client Protocol
@MainActor
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint, parameters: RequestParameters?) async throws -> T
    func request(_ endpoint: APIEndpoint, parameters: RequestParameters?) async throws -> Data
}

// MARK: - Network Client Implementation
@MainActor
final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint, parameters: RequestParameters? = nil) async throws -> T {
        let data = try await request(endpoint, parameters: parameters)
        return try decoder.decode(T.self, from: data)
    }
    
    func request(_ endpoint: APIEndpoint, parameters: RequestParameters? = nil) async throws -> Data {
        guard let url = buildURL(for: endpoint, parameters: parameters) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = parameters?.body
        
        // Add headers
        if let headers = parameters?.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add default headers if none provided
        if parameters?.headers == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidStatusCode(httpResponse.statusCode)
            }
            
            return data
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func buildURL(for endpoint: APIEndpoint, parameters: RequestParameters?) -> URL? {
        guard var urlComponents = URLComponents(string: endpoint.path) else {
            return nil
        }
        
        // Add query parameters
        if let queryItems = parameters?.queryItems {
            urlComponents.queryItems = queryItems
        }
        
        return urlComponents.url
    }
}

// MARK: - Request Parameters
struct RequestParameters {
    let queryItems: [URLQueryItem]?
    let body: Data?
    let headers: [String: String]?
    
    init(queryItems: [URLQueryItem]? = nil, body: Data? = nil, headers: [String: String]? = nil) {
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
}


// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case noData
    case invalidStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .invalidStatusCode(let code):
            return "Invalid status code: \(code)"
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}
