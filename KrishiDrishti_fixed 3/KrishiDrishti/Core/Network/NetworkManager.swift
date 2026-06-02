// Core/Network/NetworkManager.swift
// KrishiDrishti — Top-level networking orchestrator with error mapping, request logging, and exponential backoff retry logic

import Foundation

protocol NetworkManagerProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint, baseURL: String, retryCount: Int) async throws -> T
    func requestData(_ endpoint: Endpoint, baseURL: String, retryCount: Int) async throws -> Data
}

final class NetworkManager: NetworkManagerProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func request<T: Decodable>(_ endpoint: Endpoint, baseURL: String, retryCount: Int = 3) async throws -> T {
        let request = try endpoint.asURLRequest(baseURL: baseURL)
        let data = try await executeWithRetry(request, attemptsRemaining: retryCount)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // Log response parsing issue
            throw NSError(domain: "NetworkManager", code: 422, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse response payload: \(error.localizedDescription)",
                NSUnderlyingErrorKey: error
            ])
        }
    }

    func requestData(_ endpoint: Endpoint, baseURL: String, retryCount: Int = 3) async throws -> Data {
        let request = try endpoint.asURLRequest(baseURL: baseURL)
        return try await executeWithRetry(request, attemptsRemaining: retryCount)
    }

    private func executeWithRetry(_ request: URLRequest, attemptsRemaining: Int) async throws -> Data {
        do {
            #if DEBUG
            if let url = request.url {
                print("NetworkRequest: [\(request.httpMethod ?? "GET")] \(url.absoluteString)")
            }
            #endif
            let (data, _) = try await apiClient.execute(request)
            return data
        } catch {
            if attemptsRemaining > 0 {
                let delaySeconds = pow(2.0, Double(3 - attemptsRemaining)) // 1s, 2s, 4s...
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                return try await executeWithRetry(request, attemptsRemaining: attemptsRemaining - 1)
            } else {
                throw error
            }
        }
    }
}
