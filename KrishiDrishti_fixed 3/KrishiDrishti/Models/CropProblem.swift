// Models/CropProblem.swift
// KrishiDrishti — Clean crop disease model structure for real inference results

import SwiftUI

enum ScanState: Equatable {
    case idle, scanning, diagnosed
    case error(String)
}

enum Severity: String, Codable, CaseIterable {
    case low = "Low", medium = "Medium", high = "High"

    var color: Color { AppTheme.severityColor(self) }
    var bgColor: Color { AppTheme.severityBg(self) }

    var icon: String {
        switch self {
        case .low:    return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high:   return "xmark.octagon.fill"
        }
    }
    
    var spokenPrefix: String {
        switch self {
        case .low:    return "Good news. Your crop looks healthy."
        case .medium: return "Attention needed. Possible disease detected."
        case .high:   return "High alert. Please take action immediately."
        }
    }
}

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en-IN"
    var id: String { rawValue }
    var label: String { "EN" }
    var remedyIntro: String { "Here is the recommended treatment." }
}

struct CropProblem: Identifiable, Codable, Equatable {
    var id = UUID()
    let cropName: String
    let disease: String
    let scientificName: String
    let remedy: String
    let symptoms: [String]
    let severity: Severity
    let confidence: Double
    var scannedAt: Date = Date()
    
    var affectedArea: Double = 0.0
    var isHealthy: Bool = false

    var confidenceText: String { String(format: "%.1f%%", confidence * 100) }
    
    var timeAgo: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: scannedAt, relativeTo: Date())
    }
    
    var cropIcon: String {
        switch cropName.lowercased() {
        case "tomato":    return "🍅"
        case "maize", "corn": return "🌽"
        case "rice":      return "🌾"
        case "potato":    return "🥔"
        case "wheat":     return "🌿"
        case "sugarcane": return "🎋"
        default:          return "🌱"
        }
    }

    static func diagnose(label: String, confidence: Double) -> CropProblem {
        let cleanLabel = label.lowercased()
        
        let cropName: String
        let scientificName: String
        
        if cleanLabel.contains("tomato") {
            cropName = "Tomato"
            scientificName = "Solanum lycopersicum"
        } else if cleanLabel.contains("corn") || cleanLabel.contains("maize") {
            cropName = "Maize"
            scientificName = "Zea mays"
        } else if cleanLabel.contains("rice") || cleanLabel.contains("paddy") {
            cropName = "Rice"
            scientificName = "Oryza sativa"
        } else if cleanLabel.contains("potato") {
            cropName = "Potato"
            scientificName = "Solanum tuberosum"
        } else if cleanLabel.contains("wheat") || cleanLabel.contains("grain") {
            cropName = "Wheat"
            scientificName = "Triticum aestivum"
        } else if cleanLabel.contains("sugarcane") {
            cropName = "Sugarcane"
            scientificName = "Saccharum officinarum"
        } else {
            let parsed = label.split(separator: ",").first.map { String($0) } ?? label
            cropName = parsed.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
            scientificName = "N/A"
        }
        
        return CropProblem(
            cropName: cropName,
            disease: "No Disease Detected",
            scientificName: scientificName,
            remedy: "Crop appears healthy. Continue normal watering, balanced fertilization, and routine monitoring.",
            symptoms: ["Healthy green foliage", "No visible lesions or discoloration"],
            severity: .low,
            confidence: confidence,
            affectedArea: 0.0,
            isHealthy: true
        )
    }

    static func noCropDetected(confidence: Double) -> CropProblem {
        return CropProblem(
            cropName: "No Crop/Plant Detected",
            disease: "No crop or plant available to scan",
            scientificName: "N/A",
            remedy: "Please scan a crop, plant, or leaf to perform health analysis.",
            symptoms: ["Scanned object is not a crop, plant, or vegetation."],
            severity: .low,
            confidence: confidence,
            affectedArea: 0.0,
            isHealthy: false
        )
    }

    static let sampleHistory: [CropProblem] = []
}
