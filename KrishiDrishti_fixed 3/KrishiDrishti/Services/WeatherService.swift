// Services/WeatherService.swift
// KrishiDrishti — Refactored Weather Service routing requests via WeatherRepository and location updates

import SwiftUI
import CoreLocation
import Combine

@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMsg: String?
    @Published var isOffline = false

    private let manager = CLLocationManager()
    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol = DIContainer.shared.resolve(type: WeatherRepositoryProtocol.self)) {
        self.repository = repository
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        // Preload cache for instant UI
        if let cached = OfflineCacheService.shared.loadCachedWeather() {
            self.weather = cached
        }
    }

    func start() {
        let isConnected = NetworkMonitor.shared.isConnected
        guard isConnected else {
            isOffline = true
            isLoading = false
            errorMsg = "Showing offline weather"
            if weather == nil {
                weather = OfflineCacheService.shared.loadCachedWeather()
                    ?? WeatherData(temperature: 28, humidity: 65, windSpeed: 5,
                                   weatherCode: 1, locationName: "New Delhi", isFromCache: true)
            }
            return
        }

        isOffline = false
        isLoading = true
        errorMsg = nil

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            fetchWeather(latitude: 28.6139, longitude: 77.2090, name: "New Delhi")
        }
    }

    private func fetchWeather(latitude: Double, longitude: Double, name: String) {
        Task {
            do {
                let weatherData = try await repository.getWeather(latitude: latitude, longitude: longitude, locationName: name)
                self.weather = weatherData
                self.isOffline = weatherData.isFromCache
                self.isLoading = false
                self.errorMsg = nil
            } catch {
                self.isLoading = false
                self.isOffline = true
                self.errorMsg = "Live weather unavailable. Using offline data."
                self.weather = OfflineCacheService.shared.loadCachedWeather()
                    ?? WeatherData(temperature: 28, humidity: 65, windSpeed: 5,
                                   weatherCode: 1, locationName: name, isFromCache: true)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            fetchWeather(latitude: 28.6139, longitude: 77.2090, name: "New Delhi")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, name: "Your Location")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMsg = error.localizedDescription
        fetchWeather(latitude: 28.6139, longitude: 77.2090, name: "New Delhi")
    }
}
