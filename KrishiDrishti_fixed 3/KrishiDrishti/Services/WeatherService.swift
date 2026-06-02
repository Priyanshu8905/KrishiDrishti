// Services/WeatherService.swift
// KrishiDrishti — Weather via Open-Meteo (FREE, no API key needed)
// + CoreLocation for auto-location
// + Offline cache via OfflineCacheService (works without internet)

import SwiftUI
import CoreLocation
import Combine

final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var weather:   WeatherData?
    @Published var isLoading  = false
    @Published var errorMsg:  String?
    @Published var isOffline  = false

    private let mgr = CLLocationManager()

    private struct ForecastResponse: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let relative_humidity_2m: Int
            let wind_speed_10m: Double
            let weather_code: Int
        }

        let current: Current
    }

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyKilometer
        // Load cached weather immediately for instant UI
        if let cached = OfflineCacheService.shared.loadCachedWeather() {
            weather = cached
        }
    }

    func start() {
        let network = NetworkMonitor.shared
        guard network.isConnected else {
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
        switch mgr.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: mgr.requestLocation()
        case .notDetermined: mgr.requestWhenInUseAuthorization()
        default: fetch(lat: 28.6139, lon: 77.2090, name: "New Delhi")
        }
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        switch m.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: m.requestLocation()
        default: fetch(lat: 28.6139, lon: 77.2090, name: "New Delhi")
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.first else { return }
        fetch(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude, name: "Your Location")
    }

    func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {
        errorMsg = e.localizedDescription
        fetch(lat: 28.6139, lon: 77.2090, name: "New Delhi")
    }

    func fetch(lat: Double, lon: Double, name: String) {
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&timezone=auto"
        guard let url = URL(string: urlStr) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ForecastResponse.self, from: data)
                let weather = WeatherData(
                    temperature: response.current.temperature_2m,
                    humidity: response.current.relative_humidity_2m,
                    windSpeed: response.current.wind_speed_10m,
                    weatherCode: response.current.weather_code,
                    locationName: name
                )

                await MainActor.run {
                    self.weather = weather
                    self.isOffline = false
                    self.isLoading = false
                    self.errorMsg = nil
                    OfflineCacheService.shared.saveWeather(weather)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isOffline = true
                    self.errorMsg = "Live weather unavailable. Using offline data."
                    self.weather = OfflineCacheService.shared.loadCachedWeather()
                        ?? WeatherData(
                            temperature: 28,
                            humidity: 65,
                            windSpeed: 5,
                            weatherCode: 1,
                            locationName: name,
                            isFromCache: true
                        )
                }
            }
        }
    }
}
