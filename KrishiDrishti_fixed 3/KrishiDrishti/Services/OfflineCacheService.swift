// Services/OfflineCacheService.swift
// KrishiDrishti — Persistent offline cache for weather & scan history
// Uses UserDefaults + file-based storage so the app works fully offline

import Foundation

final class OfflineCacheService {

    static let shared = OfflineCacheService()
    private init() {}

    // MARK: - Keys
    private enum Key {
        static let lastWeather   = "kd_cache_weather"
        static let scanHistory   = "kd_cache_history"
    }

    // MARK: - Weather Cache

    struct CachedWeather: Codable {
        let temperature:  Double
        let humidity:     Int
        let windSpeed:    Double
        let weatherCode:  Int
        let locationName: String
        let cachedAt:     Date
    }

    func saveWeather(_ w: WeatherData) {
        let cached = CachedWeather(
            temperature:  w.temperature,
            humidity:     w.humidity,
            windSpeed:    w.windSpeed,
            weatherCode:  w.weatherCode,
            locationName: w.locationName,
            cachedAt:     Date()
        )
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: Key.lastWeather)
        }
    }

    func loadCachedWeather() -> WeatherData? {
        guard let data = UserDefaults.standard.data(forKey: Key.lastWeather),
              let cached = try? JSONDecoder().decode(CachedWeather.self, from: data) else { return nil }

        // Return cached weather up to 24h old
        let age = Date().timeIntervalSince(cached.cachedAt)
        guard age < 86400 else { return nil }

        return WeatherData(
            temperature:  cached.temperature,
            humidity:     cached.humidity,
            windSpeed:    cached.windSpeed,
            weatherCode:  cached.weatherCode,
            locationName: cached.locationName,
            isFromCache:  true
        )
    }

    var cachedWeatherAge: String? {
        guard let data = UserDefaults.standard.data(forKey: Key.lastWeather),
              let cached = try? JSONDecoder().decode(CachedWeather.self, from: data) else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: cached.cachedAt, relativeTo: Date())
    }

    // MARK: - Scan History Persistence

    func saveScanHistory(_ history: [CropProblem]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: Key.scanHistory)
        }
    }

    func loadScanHistory() -> [CropProblem] {
        guard let data = UserDefaults.standard.data(forKey: Key.scanHistory),
              let history = try? JSONDecoder().decode([CropProblem].self, from: data) else { return [] }
        return history
    }
}
