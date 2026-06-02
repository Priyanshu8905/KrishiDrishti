// Models/CropProblem.swift
// KrishiDrishti — Core crop disease model & database

import SwiftUI

// MARK: - ScanState
enum ScanState: Equatable {
    case idle, scanning, diagnosed
    case error(String)
}

// MARK: - Severity
enum Severity: String, Codable, CaseIterable {
    case low = "Low", medium = "Medium", high = "High"

    var color: Color     { AppTheme.severityColor(self) }
    var bgColor: Color   { AppTheme.severityBg(self) }

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

// MARK: - Language
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en-IN"
    var id: String { rawValue }
    var label: String { "EN" }
    var remedyIntro: String { "Here is the recommended treatment." }
}

// MARK: - CropProblem
struct CropProblem: Identifiable, Codable {
    var id         = UUID()
    let cropName, disease, scientificName, remedy: String
    let symptoms:  [String]
    let severity:  Severity
    let confidence: Double
    var scannedAt: Date = Date()

    var confidenceText: String { String(format: "%.1f%%", confidence * 100) }
    var timeAgo: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: scannedAt, relativeTo: Date())
    }
    var cropIcon: String {
        switch cropName.lowercased() {
        case "tomato":    return "🍅"
        case "maize":     return "🌽"
        case "rice":      return "🌾"
        case "potato":    return "🥔"
        case "wheat":     return "🌿"
        case "sugarcane": return "🎋"
        default:          return "🌱"
        }
    }
}

// MARK: - Disease Database
extension CropProblem {

    static func diagnose(label: String, confidence: Double) -> CropProblem {
        let l = label.lowercased()
        if l.contains("tomato")                      { return .tomato(confidence) }
        if l.contains("corn") || l.contains("maize") { return .maize(confidence) }
        if l.contains("rice") || l.contains("paddy") { return .rice(confidence) }
        if l.contains("potato")                      { return .potato(confidence) }
        if l.contains("wheat") || l.contains("grain"){ return .wheat(confidence) }
        if l.contains("sugarcane")                   { return .sugarcane(confidence) }
        if l.contains("leaf") || l.contains("plant") || l.contains("green") ||
           l.contains("herb") || l.contains("flower") || l.contains("foliage") {
            if confidence > 0.80 { return .tomato(confidence) }
            if confidence > 0.65 { return .maize(confidence) }
            return .wheat(confidence)
        }
        return .wheat(max(confidence, 0.70))
    }

    static func tomato(_ c: Double) -> CropProblem {
        .init(cropName: "Tomato", disease: "Early Blight",
              scientificName: "Alternaria solani",
              remedy: "1. Apply Mancozeb 75 WP at 2g/litre. Spray early morning.\n2. Remove infected leaves immediately. Do not compost.\n3. Repeat spray every 7–10 days.\n4. Use drip irrigation — avoid wetting leaves.\n5. Improve air circulation by pruning lower branches.",
              symptoms: ["Concentric dark rings forming target lesions on lower leaves",
                         "Yellow halo around brown necrotic spots",
                         "Leaf curl and defoliation from the base upward"],
              severity: .high, confidence: c)
    }
    static func maize(_ c: Double) -> CropProblem {
        .init(cropName: "Maize", disease: "Northern Leaf Blight",
              scientificName: "Exserohilum turcicum",
              remedy: "1. Apply Propiconazole 25 EC at 1ml/litre.\n2. Improve field drainage to reduce humidity.\n3. Plant resistant hybrids next season.\n4. Rotate crops — avoid back-to-back maize.",
              symptoms: ["Long grey-green lesions parallel to leaf veins",
                         "Lesions up to 15cm — lower leaves dry first",
                         "Rapid spread in humid, warm conditions"],
              severity: .medium, confidence: c)
    }
    static func rice(_ c: Double) -> CropProblem {
        .init(cropName: "Rice", disease: "Bacterial Leaf Blight",
              scientificName: "Xanthomonas oryzae",
              remedy: "1. Drain the field immediately.\n2. Apply Copper Oxychloride 50 WP at 3g/litre.\n3. Stop all nitrogen fertilisation now.\n4. Use certified disease-free seeds next season.",
              symptoms: ["Water-soaked yellow stripes along leaf margins",
                         "Lesions turn white to grey as they mature",
                         "Wilting of entire tillers in severe cases"],
              severity: .high, confidence: c)
    }
    static func potato(_ c: Double) -> CropProblem {
        .init(cropName: "Potato", disease: "Late Blight",
              scientificName: "Phytophthora infestans",
              remedy: "1. Apply Cymoxanil + Mancozeb at 2.5g/litre immediately.\n2. Burn all infected material — never compost.\n3. Use drip irrigation, keep foliage dry.\n4. Harvest early if more than 30% is infected.",
              symptoms: ["Pale-green water-soaked spots on leaf tips",
                         "White fungal growth under leaves in humid conditions",
                         "Dark brown stem lesions causing plant collapse"],
              severity: .high, confidence: c)
    }
    static func wheat(_ c: Double) -> CropProblem {
        .init(cropName: "Wheat", disease: "No Disease Detected",
              scientificName: "N/A",
              remedy: "1. Crop appears healthy — continue monitoring every 7 days.\n2. Maintain balanced NPK fertilisation.\n3. Irrigate without waterlogging.\n4. Watch for rust spots (orange powder) on leaves.",
              symptoms: ["Leaves uniformly green, no visible lesions",
                         "No discolouration or spotting detected",
                         "Plant structure robust and upright"],
              severity: .low, confidence: c)
    }
    static func sugarcane(_ c: Double) -> CropProblem {
        .init(cropName: "Sugarcane", disease: "Red Rot Risk",
              scientificName: "Colletotrichum falcatum",
              remedy: "1. Use disease-free healthy seed ratoons.\n2. Treat seed with Carbendazim 50 WP at 1g/litre.\n3. Remove and burn infected stalks.\n4. Improve field drainage.",
              symptoms: ["Red internal discolouration of stalk",
                         "Sour smell from cut internodes",
                         "Yellowing and drying of leaves from top"],
              severity: .medium, confidence: c)
    }

    static let sampleHistory: [CropProblem] = [
        tomato(0.974), maize(0.891), wheat(0.988), rice(0.943), potato(0.961)
    ]
}
