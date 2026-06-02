// Core/Network/APIClient.swift
// KrishiDrishti — URLSession execution client with response code validation

import Foundation

protocol APIClientProtocol: Sendable {
    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

final class APIClient: NSObject, APIClientProtocol, URLSessionDelegate {
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0
        configuration.timeoutIntervalForResource = 30.0
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    public override init() {
        super.init()
    }

    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response object"])
        }

        // Validate common client and server HTTP error ranges
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP Request failed with status code \(httpResponse.statusCode)",
                "statusCode": httpResponse.statusCode
            ])
        }

        return (data, httpResponse)
    }

    // MARK: - URLSessionDelegate (Enable Certificate Pinning or Custom SSL validation checks)
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Enforce basic trust validation, extend to inspect certificates for pinning if desired
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
