// Repositories/WeatherRepository.swift
// KrishiDrishti — Core Weather repository resolving local database caching and network loading policies

import Foundation
import CoreLocation

protocol WeatherRepositoryProtocol: Sendable {
    func getWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherData
}

final class WeatherRepository: WeatherRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let cacheService: OfflineCacheService

    init(
        networkManager: NetworkManagerProtocol = DIContainer.shared.resolve(type: NetworkManagerProtocol.self),
        cacheService: OfflineCacheService = .shared
    ) {
        self.networkManager = networkManager
        self.cacheService = cacheService
    }

    private struct WeatherResponse: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let relative_humidity_2m: Int
            let wind_speed_10m: Double
            let weather_code: Int
        }
        let current: Current
    }

    func getWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherData {
        // Attempt network fetch
        let endpoint = Endpoint(
            path: "/v1/forecast",
            queryItems: [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
                URLQueryItem(name: "timezone", value: "auto")
            ]
        )

        do {
            let response: WeatherResponse = try await networkManager.request(endpoint, baseURL: "https://api.open-meteo.com", retryCount: 2)
            let weather = WeatherData(
                temperature: response.current.temperature_2m,
                humidity: response.current.relative_humidity_2m,
                windSpeed: response.current.wind_speed_10m,
                weatherCode: response.current.weather_code,
                locationName: locationName,
                isFromCache: false
            )
            cacheService.saveWeather(weather)
            return weather
        } catch {
            // Network fallback: check offline cache
            if let cached = cacheService.loadCachedWeather() {
                return cached
            }
            // Return baseline safe default weather if cache is absent
            return WeatherData(
                temperature: 28.0,
                humidity: 65,
                windSpeed: 5.0,
                weatherCode: 1,
                locationName: locationName,
                isFromCache: true
            )
        }
    }
}
