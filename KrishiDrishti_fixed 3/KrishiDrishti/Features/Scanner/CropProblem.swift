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

    static func diagnose(label: String, confidence: Double, isHealthy: Bool = true, affectedArea: Double = 0.0, rotDetected: Bool = false) -> CropProblem {
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
        } else if cleanLabel.contains("grape") || cleanLabel.contains("vitis") {
            cropName = "Grape"
            scientificName = "Vitis vinifera"
        } else if cleanLabel.contains("apple") {
            cropName = "Apple"
            scientificName = "Malus domestica"
        } else if cleanLabel.contains("banana") {
            cropName = "Banana"
            scientificName = "Musa acuminata"
        } else if cleanLabel.contains("orange") || cleanLabel.contains("citrus") || cleanLabel.contains("lemon") || cleanLabel.contains("lime") {
            cropName = "Citrus"
            scientificName = "Citrus spp."
        } else if cleanLabel.contains("strawberry") {
            cropName = "Strawberry"
            scientificName = "Fragaria x ananassa"
        } else {
            let parsed = label.split(separator: ",").first.map { String($0) } ?? label
            cropName = parsed.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
            scientificName = "N/A"
        }
        
        if isHealthy {
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
        
        let disease: String
        let remedy: String
        let symptoms: [String]
        let severity: Severity
        
        switch cropName {
        case "Tomato":
            if rotDetected {
                disease = "Tomato Fruit Rot"
                remedy = "Harvest ripe fruits immediately.\nApply calcium-rich fertilizers to prevent blossom end rot.\nMaintain consistent soil moisture.\nDispose of any rotting fruit away from the garden."
                symptoms = ["Dark, water-soaked spots on fruits", "Sunken leathery lesions at the blossom end", "Fungal mold on decaying areas"]
                severity = .high
            } else {
                disease = "Early Blight"
                remedy = "Remove lower infected leaves.\nApply copper-based fungicides.\nMulch the soil surface around plants.\nAvoid overhead watering."
                symptoms = ["Dark concentric ring spots on older leaves", "Leaf yellowing around spots", "Premature defoliation starting from the base"]
                severity = .medium
            }
            
        case "Potato":
            if rotDetected {
                disease = "Potato Tuber Rot"
                remedy = "Harvest in dry conditions and cure tubers before storing.\nStore in cool, dry, well-ventilated space.\nDiscard infected tubers.\nUse certified disease-free seed potatoes."
                symptoms = ["Soft, moist, decaying tubers", "Foul odor from stored potatoes", "Internal browning or blackening of tissues"]
                severity = .high
            } else {
                disease = "Late Blight"
                remedy = "Apply preventative fungicides.\nDestroy infected plant debris after harvest.\nImprove spacing to increase airflow.\nAvoid watering leaves."
                symptoms = ["Dark water-soaked lesions on leaves", "White powdery growth on leaf undersides in humid weather", "Leaf wilting and rapid collapse"]
                severity = .high
            }
            
        case "Grape":
            if rotDetected {
                disease = "Grape Black Rot"
                remedy = "Prune and destroy infected canes and mummified fruit.\nMaintain excellent canopy ventilation.\nApply early-season fungicides.\nKeep the vineyard floor clean of debris."
                symptoms = ["Reddish-brown spots on leaves", "Shriveled, hard, black mummified berries", "Small black pustules on canes"]
                severity = .high
            } else {
                disease = "Downy Mildew"
                remedy = "Apply copper fungicides before rainfall.\nAvoid overhead irrigation.\nPrune lower canopy leaves to reduce humidity.\nDestroy fallen leaves."
                symptoms = ["Yellow-green oil spots on upper leaf surfaces", "White downy fungal growth on leaf undersides", "Drying and browning of young shoots"]
                severity = .medium
            }
            
        case "Maize":
            if rotDetected {
                disease = "Corn Ear Rot"
                remedy = "Harvest early to prevent further rot.\nStore corn at moisture levels below 15%.\nUse insect-resistant hybrids.\nRotate crops next season."
                symptoms = ["White or pink mold growing on ears", "Rotting or shriveled kernels", "Discolored husks"]
                severity = .high
            } else {
                disease = "Corn Leaf Blight"
                remedy = "Rotate crops to break the pathogen cycle.\nApply recommended fungicides.\nTillage to bury crop debris.\nUse resistant corn varieties."
                symptoms = ["Long, elliptical, grayish-green leaf lesions", "Lesions turn tan and paper-like", "Early death of lower leaves"]
                severity = .medium
            }
            
        case "Rice":
            if rotDetected {
                disease = "Rice Neck Rot"
                remedy = "Avoid excessive nitrogen fertilizers.\nUse resistant crop cultivars.\nApply fungicides at late booting stage.\nEnsure proper field drainage."
                symptoms = ["Neck of panicle turns grayish-brown", "Panicles fall over or break", "Grains fail to fill or become light and chalky"]
                severity = .high
            } else {
                disease = "Rice Blast"
                remedy = "Plant resistant cultivars.\nMaintain continuous shallow water depth.\nApply silicon fertilizers.\nUse systemic fungicides."
                symptoms = ["Diamond-shaped spots with gray centers on leaves", "Spindle-shaped lesions with reddish-brown borders", "Leaf drying and death"]
                severity = .high
            }
            
        case "Wheat":
            if rotDetected {
                disease = "Wheat Head Blight"
                remedy = "Practice crop rotation with non-host crops.\nApply fungicides during flowering stage.\nPlant moderately resistant varieties.\nAvoid irrigation during flowering."
                symptoms = ["Bleached spikelets or entire heads", "Pinkish-orange fungal spore masses on glumes", "Shriveled, light kernels"]
                severity = .high
            } else {
                disease = "Wheat Rust"
                remedy = "Use rust-resistant wheat varieties.\nApply triazole fungicides.\nEliminate volunteer wheat plants.\nPlant early to escape rust development."
                symptoms = ["Orange-red pustules on leaves and stems", "Leaf yellowing and drying", "Deformed or light grains"]
                severity = .high
            }
            
        case "Apple":
            if rotDetected {
                disease = "Apple Fruit Rot"
                remedy = "Remove rotting fruit from tree and ground.\nApply protective fungicides.\nPrune to improve light and air penetration.\nStore only clean, unbruised fruit."
                symptoms = ["Circular brown lesions on fruit surface", "Concentric rings of white fungal spores", "Flesh turns soft and mushy"]
                severity = .high
            } else {
                disease = "Apple Scab"
                remedy = "Rake and destroy fallen leaves in autumn.\nApply preventative fungicides from green tip stage.\nPrune branches to dry foliage quickly."
                symptoms = ["Olive-green to black velvety spots on leaves", "Scabby, cracked brown lesions on fruit skin", "Early leaf drop"]
                severity = .medium
            }
            
        case "Citrus":
            if rotDetected {
                disease = "Citrus Fruit Rot"
                remedy = "Harvest fruits carefully to avoid wounding.\nDip in post-harvest sanitizer.\nStore at optimal temperature and low humidity.\nRemove fallen rotten fruits."
                symptoms = ["Green or blue mold on fruit rind", "Water-soaked rind lesions that soften rapidly", "Foul fermentation odor"]
                severity = .high
            } else {
                disease = "Citrus Canker"
                remedy = "Apply preventative copper fungicides.\nSanitize tools and equipment.\nPrune infected twigs during dry periods.\nWindbreaks to limit rain-splashed spread."
                symptoms = ["Raised, corky, brown lesions on leaves and fruit", "Lesions surrounded by yellow halos", "Defoliation and premature fruit drop"]
                severity = .high
            }
            
        case "Strawberry":
            if rotDetected {
                disease = "Strawberry Gray Mold"
                remedy = "Mulch with straw to keep fruit off soil.\nApply fungicides during bloom.\nAvoid overhead irrigation.\nHarvest frequently and handle gently."
                symptoms = ["Soft brown spots on berries", "Gray, dusty, velvety mold covering fruit", "Mummified berries on the vine"]
                severity = .high
            } else {
                disease = "Strawberry Leaf Spot"
                remedy = "Plant certified disease-free runners.\nPrune back foliage after harvest.\nApply copper-based sprays.\nKeep plants spaced for good airflow."
                symptoms = ["Small round purple spots on leaves", "Spots develop grayish-white centers", "Leaf drying and drop under heavy infection"]
                severity = .medium
            }
            
        default:
            if rotDetected {
                disease = "\(cropName) Decay / Rot"
                remedy = "Isolate infected plants or fruits.\nImprove aeration and reduce watering.\nDiscard decaying parts safely.\nUse clean tools to prune."
                symptoms = ["Soft, mushy, discolored areas", "Foul odor and mold growth", "Rapid tissue decay"]
                severity = .high
            } else {
                disease = "\(cropName) Leaf Spot"
                remedy = "Remove infected foliage.\nAvoid overhead irrigation.\nApply organic bio-fungicides.\nImprove spacing for air circulation."
                symptoms = ["Dark spots on leaf surfaces", "Yellow halo around lesions", "Leaf browning and drop"]
                severity = .medium
            }
        }
        
        return CropProblem(
            cropName: cropName,
            disease: disease,
            scientificName: scientificName,
            remedy: remedy,
            symptoms: symptoms,
            severity: severity,
            confidence: confidence,
            affectedArea: affectedArea,
            isHealthy: false
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
