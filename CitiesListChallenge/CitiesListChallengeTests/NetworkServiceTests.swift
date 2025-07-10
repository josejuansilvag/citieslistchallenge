//
//  NetworkServiceTests.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 09/07/25.
//

import XCTest
@testable import CitiesListChallenge

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
        let mockCities = [
            CityJSON(country: "AR", name: "Buenos Aires", _id: 1, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037)),
            CityJSON(country: "BR", name: "Rio de Janeiro", _id: 2, coord: CoordinateJSON(lon: -43.1729, lat: -22.9068))
        ]
        
        let jsonData = try JSONEncoder().encode(mockCities)
        mockNetworkClient.mockData = jsonData
        let result = try await networkService.downloadCityData()
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Buenos Aires")
        XCTAssertEqual(result[0].country, "AR")
        XCTAssertEqual(result[1].name, "Rio de Janeiro")
        XCTAssertEqual(result[1].country, "BR")
    }
    
    func testDownloadCityDataFailure() async {
        mockNetworkClient.shouldFail = true
        do {
            _ = try await networkService.downloadCityData()
            XCTFail("Should throw an error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Network Client Tests
    
    func testNetworkClientRequestSuccess() async throws {
        let mockCity = CityJSON(country: "AR", name: "Buenos Aires", _id: 1, coord: CoordinateJSON(lon: -58.3816, lat: -34.6037))
        let jsonData = try JSONEncoder().encode([mockCity])
        mockNetworkClient.mockData = jsonData
        let result: [CityJSON] = try await mockNetworkClient.request(.cities, parameters: nil)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Buenos Aires")
    }
    
    func testNetworkClientRequestFailure() async {
        mockNetworkClient.shouldFail = true
        do {
            let _: [CityJSON] = try await mockNetworkClient.request(.cities, parameters: nil)
            XCTFail("Should throw an error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testNetworkClientRawDataRequest() async throws {
        let testData = "Hello, World!".data(using: .utf8)!
        mockNetworkClient.mockData = testData
        let result = try await mockNetworkClient.request(.cities, parameters: nil)
        XCTAssertEqual(result, testData)
    }
    
    // MARK: - API Endpoint Tests
    
    func testAPIEndpointCities() {
        let endpoint = APIEndpoint.cities
        
        XCTAssertEqual(endpoint.path, "https://gist.githubusercontent.com/hernan-uala/dce8843a8edbe0b0018b32e137bc2b3a/raw/0996accf70cb0ca0e16f9a99e0ee185fafca7af1/cities.json")
        XCTAssertEqual(endpoint.method, .GET)
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkErrorDescriptions() {
        let invalidURLError = NetworkError.invalidURL
        let requestFailedError = NetworkError.requestFailed(NSError(domain: "Test", code: 500, userInfo: nil))
        let invalidResponseError = NetworkError.invalidResponse
        let decodingError = NetworkError.decodingError(NSError(domain: "Test", code: 0, userInfo: nil))
        let noDataError = NetworkError.noData
        let invalidStatusCodeError = NetworkError.invalidStatusCode(404)
        
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
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.PATCH.rawValue, "PATCH")
    }
    
    // MARK: - Request Parameters Tests
    
    func testRequestParameters() {
        let queryItems = [URLQueryItem(name: "test", value: "value")]
        let body = "test body".data(using: .utf8)
        let headers = ["Content-Type": "application/json"]
        
        let parameters = RequestParameters(
            queryItems: queryItems,
            body: body,
            headers: headers
        )
        
        XCTAssertEqual(parameters.queryItems?.count, 1)
        XCTAssertEqual(parameters.queryItems?.first?.name, "test")
        XCTAssertEqual(parameters.queryItems?.first?.value, "value")
        XCTAssertEqual(parameters.body, body)
        XCTAssertEqual(parameters.headers?.count, 1)
        XCTAssertEqual(parameters.headers?["Content-Type"], "application/json")
    }
    
    func testRequestParametersWithDefaults() {
        let parameters = RequestParameters()
        
        XCTAssertNil(parameters.queryItems)
        XCTAssertNil(parameters.body)
        XCTAssertNil(parameters.headers)
    }
}
