// Models/WeatherModel.swift
// KrishiDrishti — Weather data model

import SwiftUI

struct WeatherData {
    let temperature: Double
    let humidity:    Int
    let windSpeed:   Double
    let weatherCode: Int
    let locationName: String
    var isFromCache = false

    var condition: String {
        switch weatherCode {
        case 0:       return "Clear Sky"
        case 1...3:   return "Partly Cloudy"
        case 45, 48:  return "Foggy"
        case 51...65: return "Rainy"
        case 80...82: return "Rain Showers"
        case 95:      return "Thunderstorm"
        default:      return "Cloudy"
        }
    }

    var sfSymbol: String {
        switch weatherCode {
        case 0:       return "sun.max.fill"
        case 1...3:   return "cloud.sun.fill"
        case 45, 48:  return "cloud.fog.fill"
        case 51...65: return "cloud.drizzle.fill"
        case 80...95: return "cloud.rain.fill"
        default:      return "cloud.fill"
        }
    }

    var gradientColors: [Color] {
        switch weatherCode {
        case 0:       return [Color(red:0.18,green:0.52,blue:0.95), Color(red:0.48,green:0.78,blue:1.0)]
        case 1...3:   return [Color(red:0.38,green:0.56,blue:0.80), Color(red:0.60,green:0.76,blue:0.92)]
        case 45...65: return [Color(red:0.28,green:0.45,blue:0.62), Color(red:0.48,green:0.62,blue:0.76)]
        case 80...95: return [Color(red:0.18,green:0.30,blue:0.52), Color(red:0.35,green:0.50,blue:0.72)]
        default:      return [AppTheme.greenLight, AppTheme.green]
        }
    }

    enum DiseaseRisk { case low, moderate, high }
    var diseaseRisk: DiseaseRisk {
        if humidity > 80 && temperature > 20 { return .high }
        if humidity > 65 && temperature > 15 { return .moderate }
        return .low
    }

    var riskLabel: String {
        switch diseaseRisk { case .low: return "Low Risk"; case .moderate: return "Moderate Risk"; case .high: return "High Risk" }
    }
    var riskColor: Color {
        switch diseaseRisk { case .low: return .green; case .moderate: return .orange; case .high: return .red }
    }
    var riskIcon: String {
        switch diseaseRisk {
        case .low:      return "checkmark.shield.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high:     return "xmark.octagon.fill"
        }
    }

    func advisory(for crops: [String]) -> String {
        let cropList = crops.isEmpty ? "your crops" : crops.prefix(2).joined(separator: " and ")
        switch diseaseRisk {
        case .high:
            return humidity > 85
                ? "Very high fungal risk today. Spray Mancozeb on \(cropList) preventively."
                : "High blight risk. Inspect \(cropList) immediately. Apply fungicide if symptoms appear."
        case .moderate:
            return weatherCode >= 61 && weatherCode <= 65
                ? "Rain detected. Hold spraying — reschedule for tomorrow morning."
                : "Moderate risk. Good time to spray \(cropList). Check fields for early signs."
        case .low:
            return weatherCode == 0
                ? "Perfect weather! Ideal day to inspect \(cropList) and apply preventive treatment."
                : "Low disease risk. Good conditions for fertilisation and irrigation of \(cropList)."
        }
    }

    var sourceLabel: String {
        isFromCache ? "Offline cache" : "Live weather"
    }
}
