// Tests/UnitTests.swift
// KrishiDrishti Tests — Unit tests for models, managers, and utility classes

import XCTest
@testable import KrishiDrishti

final class KrishiDrishtiUnitTests: XCTestCase {

    func testDIContainerResolvesRegisteredServices() {
        let coreMLService = DIContainer.shared.resolve(type: CoreMLServiceProtocol.self)
        XCTAssertNotNil(coreMLService)

        let keychainManager = DIContainer.shared.resolve(type: KeychainManagerProtocol.self)
        XCTAssertNotNil(keychainManager)

        let predictionEngine = DIContainer.shared.resolve(type: PredictionEngineProtocol.self)
        XCTAssertNotNil(predictionEngine)
    }

    func testFuzzySearchLevenshteinDistance() {
        let distance1 = FuzzySearch.levenshtein("tomato", "tomato")
        XCTAssertEqual(distance1, 0)

        let distance2 = FuzzySearch.levenshtein("tomato", "potato")
        XCTAssertEqual(distance2, 2)

        let distance3 = FuzzySearch.levenshtein("", "apple")
        XCTAssertEqual(distance3, 5)
    }

    func testFuzzySearchScore() {
        let exactScore = FuzzySearch.score(query: "Tomato", candidate: "Tomato")
        XCTAssertEqual(exactScore, 1.0)

        let prefixScore = FuzzySearch.score(query: "toma", candidate: "Tomato")
        XCTAssertGreaterThan(prefixScore, 0.5)
    }

    func testCropProblemSeverityColors() {
        let lowSeverity = Severity.low
        XCTAssertEqual(lowSeverity.icon, "checkmark.shield.fill")

        let highSeverity = Severity.high
        XCTAssertEqual(highSeverity.icon, "xmark.octagon.fill")
    }

    func testSecurityDataEncryption() throws {
        let securityManager = SecurityManager()
        let originalText = "Sensitive Farmer Phone Number"
        let data = originalText.data(using: .utf8)!

        let encrypted = try securityManager.encryptData(data: data)
        XCTAssertNotEqual(encrypted, data)

        let decrypted = try securityManager.decryptData(encryptedData: encrypted)
        let decryptedText = String(data: decrypted, encoding: .utf8)
        XCTAssertEqual(decryptedText, originalText)
    }

    func testEndpointURLConstruction() throws {
        let endpoint = Endpoint(
            path: "/v1/test",
            queryItems: [URLQueryItem(name: "q", value: "search")],
            method: "POST"
        )
        let request = try endpoint.asURLRequest(baseURL: "https://api.test.com")

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.test.com/v1/test?q=search")
    }
}
