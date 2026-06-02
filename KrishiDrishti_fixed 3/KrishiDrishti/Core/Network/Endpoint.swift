// Core/Network/Endpoint.swift
// KrishiDrishti — Type-safe definition of network request configurations

import Foundation

struct Endpoint {
    var path: String
    var queryItems: [URLQueryItem]?
    var headers: [String: String]?
    var body: Data?
    var method: String

    init(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        method: String = "GET"
    ) {
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.method = method
    }

    func asURLRequest(baseURL: String) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw NSError(domain: "Endpoint", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid base URL: \(baseURL) or path: \(path)"])
        }

        if let queryItems = queryItems {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NSError(domain: "Endpoint", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to construct URL from components"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        return request
    }
}
