//
//  NetworkServiceTests.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 09/07/25.
//

import XCTest
@testable import CitiesListChallenge

@MainActor
class NetworkServiceTests: XCTestCase {
    var networkService: NetworkServiceProtocol!
    var mockNetworkClient: MockNetworkClient!
    
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        networkService = NetworkService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() {
        networkService = nil
        mockNetworkClient = nil
        super.tearDown()
    }
    
    // MARK: - Network Service Tests
    
    func testDownloadCityDataSuccess() async throws {
        // Given: Valid city JSON data
        let mockCities = [
            CityJSON(country: "AR", name: "Buenos Aires", _id: 1, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)),
            CityJSON(country: "BR", name: "Rio de Janeiro", _id: 2, coord: CoordinateJSON(lon: -43.1729, lat: -22.9068))
        ]
        let jsonData = try JSONEncoder().encode(mockCities)
        mockNetworkClient.mockData = jsonData
        
        // When: Calling downloadCityData()
        let result = try await networkService.downloadCityData()
        
        // Then: It should return the decoded cities
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Buenos Aires")
        XCTAssertEqual(result[0].country, "AR")
        XCTAssertEqual(result[1].name, "Rio de Janeiro")
        XCTAssertEqual(result[1].country, "BR")
    }
    
    func testDownloadCityDataFailure() async {
        // Given: A network client set to fail
        mockNetworkClient.shouldFail = true
        
        // When & Then: downloadCityData should throw a NetworkError
        do {
            _ = try await networkService.downloadCityData()
            XCTFail("Should throw an error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Network Client Tests
    
    func testNetworkClientRequestSuccess() async throws {
        // Given: A single city encoded as JSON data
        let mockCity = CityJSON(country: "AR", name: "Buenos Aires", _id: 1, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037))
        let jsonData = try JSONEncoder().encode([mockCity])
        mockNetworkClient.mockData = jsonData
        
        // When: Requesting decoded CityJSON from endpoint
        let result: [CityJSON] = try await mockNetworkClient.request(.cities, parameters: nil)
        
        // Then: It should return the expected city
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Buenos Aires")
    }
    
    func testNetworkClientRequestFailure() async {
        // Given: A network client set to fail
        mockNetworkClient.shouldFail = true
        
        // When & Then: request should throw a NetworkError
        do {
            let _: [CityJSON] = try await mockNetworkClient.request(.cities, parameters: nil)
            XCTFail("Should throw an error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testNetworkClientRawDataRequest() async throws {
        // Given: Mock data set as plain Data
        let testData = "Hello, World!".data(using: .utf8)!
        mockNetworkClient.mockData = testData
        
        // When: Requesting raw data from endpoint
        let result = try await mockNetworkClient.request(.cities, parameters: nil)
        
        // Then: It should return the exact raw data
        XCTAssertEqual(result, testData)
    }
    
    // MARK: - API Endpoint Tests
    
    func testAPIEndpointCities() {
        // Given: A predefined cities endpoint
        
        // Then: Path and method should be correct
        let endpoint = APIEndpoint.cities
        XCTAssertEqual(endpoint.path, "https://gist.githubusercontent.com/hernan-uala/dce8843a8edbe0b0018b32e137bc2b3a/raw/0996accf70cb0ca0e16f9a99e0ee185fafca7af1/cities.json")
        XCTAssertEqual(endpoint.method, .GET)
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkErrorDescriptions() {
        // Given: All network error cases
        let invalidURLError = NetworkError.invalidURL
        let requestFailedError = NetworkError.requestFailed(NSError(domain: "Test", code: 500, userInfo: nil))
        let invalidResponseError = NetworkError.invalidResponse
        let decodingError = NetworkError.decodingError(NSError(domain: "Test", code: 0, userInfo: nil))
        let noDataError = NetworkError.noData
        let invalidStatusCodeError = NetworkError.invalidStatusCode(404)
        
        // Then: Each error should return a descriptive message
        XCTAssertNotNil(invalidURLError.errorDescription)
        XCTAssertNotNil(requestFailedError.errorDescription)
        XCTAssertNotNil(invalidResponseError.errorDescription)
        XCTAssertNotNil(decodingError.errorDescription)
        XCTAssertNotNil(noDataError.errorDescription)
        XCTAssertNotNil(invalidStatusCodeError.errorDescription)
        
        XCTAssertTrue(invalidURLError.errorDescription?.contains("Invalid URL") ?? false)
        XCTAssertTrue(requestFailedError.errorDescription?.contains("Request failed") ?? false)
        XCTAssertTrue(invalidResponseError.errorDescription?.contains("Invalid response") ?? false)
        XCTAssertTrue(decodingError.errorDescription?.contains("Decoding error") ?? false)
        XCTAssertTrue(noDataError.errorDescription?.contains("No data") ?? false)
        XCTAssertTrue(invalidStatusCodeError.errorDescription?.contains("404") ?? false)
    }
    
    // MARK: - HTTP Method Tests
    
    func testHTTPMethods() {
        // Then: HTTP method raw values should match expectations
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.PATCH.rawValue, "PATCH")
    }
    
    // MARK: - Request Parameters Tests
    
    func testRequestParameters() {
        // Given: Custom request parameters
        let queryItems = [URLQueryItem(name: "test", value: "value")]
        let body = "test body".data(using: .utf8)
        let headers = ["Content-Type": "application/json"]
        
        let parameters = RequestParameters(
            queryItems: queryItems,
            body: body,
            headers: headers
        )
        
        // Then: All parameters should be correctly set
        XCTAssertEqual(parameters.queryItems?.count, 1)
        XCTAssertEqual(parameters.queryItems?.first?.name, "test")
        XCTAssertEqual(parameters.queryItems?.first?.value, "value")
        XCTAssertEqual(parameters.body, body)
        XCTAssertEqual(parameters.headers?.count, 1)
        XCTAssertEqual(parameters.headers?["Content-Type"], "application/json")
    }
    
    func testRequestParametersWithDefaults() {
        // Given: RequestParameters initialized with no arguments
        let parameters = RequestParameters()
        
        // Then: All properties should be nil
        XCTAssertNil(parameters.queryItems)
        XCTAssertNil(parameters.body)
        XCTAssertNil(parameters.headers)
    }
}
