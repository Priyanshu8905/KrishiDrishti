// ViewModels/KrishiBotViewModel.swift
// KrishiDrishti — Upgraded KrishiBot ViewModel integrating Local AI prediction engines and NaturalLanguage sentiment detection

import SwiftUI
import Vision
import NaturalLanguage

struct BotMsg: Identifiable {
    let id = UUID()
    let role: BotRole
    var text: String
    var image: UIImage?
    var chart: BotChart?
    var distressAlert = false
}

enum BotRole { case user, bot }

struct BotChart: Identifiable {
    let id = UUID()
    let title: String
    var bars: [BotBar]
    let unit: String
}

struct BotBar: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

@MainActor
final class KrishiBotVM: ObservableObject {

    @Published var messages: [BotMsg] = []
    @Published var input: String = ""
    @Published var thinking: Bool = false
    @Published var isAnalyzingImage: Bool = false

    var currentWeather: WeatherData?
    var farmerCrops: [String] = []
    var farmerName: String = ""

    private let predictionEngine: PredictionEngineProtocol
    private let offlineKnowledge = LocalKnowledgeStore.load()

    private var geminiSystem: String {
        """
        You are KrishiBot, a senior agronomist with 25 years experience in Indian field agriculture.
        Expertise: crop disease, IPM, soil science, fertilization, irrigation, seed treatment.
        Rules:
        - Answer EXACTLY what is asked. Lead with direct answer.
        - Give specific doses (g/litre, kg/hectare). Name active ingredients.
        - Keep response under 300 words. Use simple English.
        - If you don't know, say so honestly.
        Context: Farmer \(farmerName.isEmpty ? "" : farmerName).
        Crops: \(farmerCrops.isEmpty ? "not specified" : farmerCrops.joined(separator: ", ")).
        \(currentWeather.map { "Weather: \(Int($0.temperature))°C, \($0.humidity)% humidity, \($0.condition) at \($0.locationName)." } ?? "")
        """
    }

    init(predictionEngine: PredictionEngineProtocol = DIContainer.shared.resolve(type: PredictionEngineProtocol.self)) {
        self.predictionEngine = predictionEngine

        messages.append(BotMsg(role: .bot, text: """
        👋 **Hello! I am KrishiBot.**

        I am trained in crop science, agronomy, soil health, and integrated pest management.

        Ask me anything:
        • "What is early blight in tomato?"
        • "How much urea for wheat per acre?"
        • "Why are my maize leaves turning yellow?"
        • "What spray for rice bacterial blight?"
        • Upload a 📷 photo for instant crop analysis.
        """))
    }

    func analyzePhoto(_ img: UIImage, text: String = "") {
        let userText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let bubbleText = userText.isEmpty ? "📷 Photo submitted for analysis:" : userText
        messages.append(BotMsg(role: .user, text: bubbleText, image: img))
        input = ""
        thinking = true
        isAnalyzingImage = true
        Task {
            var diagnosisResult: CropProblem? = nil
            if GeminiService.shared.isConfigured {
                diagnosisResult = await GeminiService.shared.analyzeCropImage(image: img)
                if let diagnosis = diagnosisResult, (diagnosis.cropName == "Unknown" || diagnosis.cropName.lowercased().contains("unknown") || diagnosis.disease.lowercased().contains("no crop")) {
                    diagnosisResult = CropProblem.noCropDetected(confidence: diagnosis.confidence)
                }
            }
            
            if diagnosisResult == nil {
                do {
                    diagnosisResult = try await predictionEngine.predictCropProblem(from: img)
                } catch {
                    diagnosisResult = CropProblem.diagnose(label: "leaf", confidence: 0.75)
                }
            }
            
            let finalDiagnosis = diagnosisResult ?? CropProblem.diagnose(label: "leaf", confidence: 0.75)
            let reply = photoReply(diagnosis: finalDiagnosis)
            self.isAnalyzingImage = false
            self.thinking = false
            self.messages.append(reply)
        }
    }

    private func photoReply(diagnosis: CropProblem) -> BotMsg {
        let confidencePercent = min(Int(diagnosis.confidence * 100), 99)
        let statusEmoji = diagnosis.isHealthy ? "✅" : "⚠️"
        let healthText = diagnosis.isHealthy ? "Healthy" : "Diseased / Rotten"
        
        var detailsText = """
        \(diagnosis.cropIcon) **\(diagnosis.cropName) Analysis Result**
        
        • **Health Status:** \(statusEmoji) \(healthText)
        • **Condition:** \(diagnosis.isHealthy ? "No disease detected" : diagnosis.disease)
        • **Confidence:** \(confidencePercent)%
        • **Affected Leaf/Fruit Area:** \(String(format: "%.1f%%", diagnosis.affectedArea))
        • **Recommended Treatment:**
        \(diagnosis.remedy)
        """
        
        if !diagnosis.isHealthy && !diagnosis.symptoms.isEmpty {
            detailsText += "\n\n• **Observed Symptoms:**"
            for symptom in diagnosis.symptoms {
                detailsText += "\n  - \(symptom)"
            }
        }
        
        return BotMsg(role: .bot, text: detailsText)
    }

    func sendText() {
        let query = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let sentiment = predictionEngine.analyzeSentiment(of: query)
        let isDistressed = sentiment == "negative"

        messages.append(BotMsg(role: .user, text: query, distressAlert: isDistressed))
        input = ""
        thinking = true

        Task {
            var answer = ""

            if GeminiService.shared.isConfigured,
               let aiAnswer = await GeminiService.shared.ask(system: geminiSystem, user: query) {
                answer = aiAnswer
            } else {
                let localResponse = self.expertReply(query)
                answer = localResponse.text
            }

            if isDistressed {
                answer = "🚨 *Distress warning: High concern detected. Take action promptly.*\n\n" + answer
            }

            self.thinking = false
            self.messages.append(BotMsg(role: .bot, text: answer, distressAlert: isDistressed))
        }
    }

    // MARK: - Offline expert engine fallback
    private func expertReply(_ raw: String) -> BotMsg {
        let q = raw.lowercased()
        let w = currentWeather
        let name = farmerName.isEmpty ? "Farmer" : farmerName

        var crop: String? = nil
        if q.contains("tomato") { crop = "Tomato" }
        else if q.contains("potato") { crop = "Potato" }
        else if q.contains("wheat") { crop = "Wheat" }
        else if q.contains("rice") || q.contains("paddy") { crop = "Rice" }
        else if q.contains("corn") || q.contains("maize") { crop = "Maize" }
        else if q.contains("sugarcane") { crop = "Sugarcane" }
        else if q.contains("grape") { crop = "Grape" }

        if isGreeting(q) {
            return BotMsg(role: .bot, text: "Hello \(name)! 👋 How can I help you with your crops today?")
        }

        if has(q, ["weather", "temperature", "humidity", "rain", "forecast"]) {
            if let w {
                return BotMsg(role: .bot, text: """
                🌤️ **Weather — \(w.locationName)**
                🌡️ **\(String(format:"%.1f",w.temperature))°C** · 💧 **\(w.humidity)%** · 💨 **\(Int(w.windSpeed)) km/h**
                
                **Disease Risk:** \(w.riskLabel)
                **Advisory:** \(w.advisory(for: crop != nil ? [crop!] : farmerCrops))
                """)
            }
            return BotMsg(role: .bot, text: "🌤️ Weather is still loading. Please wait a moment.")
        }

        let isDiseaseQuery = has(q, ["disease", "blight", "rot", "wilt", "mildew", "rust", "spot", "spots", "mold", "fungus", "fungal", "symptom", "sick", "die", "dying", "problem", "damage", "lesion", "yellow", "brown", "treatment", "cure", "remedy"])

        if isDiseaseQuery, let reference = knowledgeReply(for: q) {
            return reference
        }

        if has(q, ["fertilizer", "urea", "dap", "npk", "nitrogen", "potash", "manure"]) {
            if crop == "Tomato" {
                return BotMsg(role: .bot, text: """
                🍅 **Tomato Fertilization Advice**
                • Pre-planting: Incorporate well-rotted manure or compost.
                • Growth stage: Apply balanced NPK (e.g. 10-10-10) to support foliage growth.
                • Fruit stage: Reduce nitrogen and increase potassium and calcium to support healthy fruit development.
                """)
            } else if crop == "Wheat" {
                return BotMsg(role: .bot, text: """
                🌾 **Wheat Fertilization Advice**
                • Sowing (Basal): Apply 50 kg DAP and 20 kg Muriate of Potash per acre during sowing.
                • First Irrigation (21 Days): Apply 40 kg Urea per acre to boost crown root growth.
                • Jointing Stage (45 Days): Top dress with another 40 kg Urea per acre.
                """)
            } else if crop == "Rice" {
                return BotMsg(role: .bot, text: """
                🌾 **Rice Fertilization Advice**
                • Basal Dose: Mix NPK or DAP and Potash during soil preparation before transplanting.
                • Tillering Stage: Apply Urea top dressing to promote tillers.
                • Panicle Initiation: Apply final top dressing of Nitrogen to boost grain yield.
                """)
            } else if crop == "Potato" {
                return BotMsg(role: .bot, text: """
                🥔 **Potato Fertilization Advice**
                • Planting: Apply high phosphorus fertilizer (like DAP) in bands next to seed tubers.
                • Tubers Initiation: Apply nitrogen (Urea) and potassium (MOP) to encourage tuber bulk growth.
                • Calcium: Spray calcium nitrate to improve tuber skin quality and prevent hollow heart.
                """)
            } else if crop == "Maize" {
                return BotMsg(role: .bot, text: """
                🌽 **Maize Fertilization Advice**
                • Sowing: Apply NPK or DAP starter fertilizer near seed rows.
                • Knee-High Stage: Top dress with Urea (heavy nitrogen requirement) to support rapid stem elongation.
                • Tasseling: Ensure adequate potassium and nitrogen levels for kernel development.
                """)
            } else {
                return BotMsg(role: .bot,
                    text: """
                    🌱 **Fertilizer — Common Benchmarks (kg/hectare)**
                    | Crop | N | P | K |
                    |---|---|---|---|
                    | Wheat | 120 | 46 | 30 |
                    | Rice | 120 | 46 | 30 |
                    | Maize | 150 | 69 | 36 |
                    | Tomato | 150 | 75 | 100 |
                    Tell me: crop + growth stage + area for exact dose.
                    """,
                    chart: BotChart(title: "N per Crop (kg/ha)", bars: [
                        BotBar(label: "Wheat",  value: 120, color: AppTheme.green),
                        BotBar(label: "Rice",   value: 120, color: AppTheme.greenLight),
                        BotBar(label: "Maize",  value: 150, color: AppTheme.amber),
                        BotBar(label: "Tomato", value: 150, color: .red)
                    ], unit: "kg"))
            }
        }

        if has(q, ["pest", "insect", "bug", "aphid", "borer", "thrip", "worm", "caterpillar"]) {
            if crop == "Tomato" {
                return BotMsg(role: .bot, text: """
                🍅 **Tomato Pest Control**
                • Aphids & Whiteflies: Use yellow sticky traps, or spray Neem oil (5 ml/litre) or Imidacloprid (0.5 ml/litre).
                • Fruit Borer: Spray Bacillus thuringiensis (Bt) or Spinosad to control caterpillars.
                """)
            } else if crop == "Potato" {
                return BotMsg(role: .bot, text: """
                🥔 **Potato Pest Control**
                • Potato Tuber Moth: Store tubers under clean dry sand, spray Chlorpyrifos in field.
                • Aphids: Spray Imidacloprid to prevent transmission of viral diseases.
                """)
            } else if crop == "Maize" {
                return BotMsg(role: .bot, text: """
                🌽 **Maize Pest Control**
                • Fall Armyworm: Spray Spinetoram or Emamectin Benzoate (0.5 g/litre) into leaf whorls.
                • Stem Borer: Apply Carbofuran granules in leaf whorls at early vegetative stage.
                """)
            } else if crop == "Rice" {
                return BotMsg(role: .bot, text: """
                🌾 **Rice Pest Control**
                • Stem Borer: Use pheromone traps; spray Chlorantraniliprole 18.5 SC (0.3 ml/litre).
                • Brown Plant Hopper: Maintain clean alleys; spray Pymetrozine or Imidacloprid.
                """)
            } else if crop == "Wheat" {
                return BotMsg(role: .bot, text: """
                🌾 **Wheat Pest Control**
                • Termites: Treat seeds with Chlorpyrifos before sowing; irrigate field if termites appear.
                • Aphids: Spray Imidacloprid (0.5 ml/litre) if population exceeds 5-10 aphids per ear.
                """)
            } else {
                return BotMsg(role: .bot, text: """
                🐛 **Pest Management — IPM Guide**
                | Pest | Product | Dose |
                |---|---|---|
                | Aphids | Imidacloprid 17.8 SL | 0.5 ml/litre |
                | Stem Borer | Chlorpyrifos 20 EC | 2 ml/litre |
                | Fall Armyworm | Emamectin Benzoate | 0.5 g/litre |
                | Whitefly | Spiromesifen 22.9 SC | 0.9 ml/litre |
                Spray 7–9 AM or 4–6 PM. Avoid wind >15 km/h.
                """)
            }
        }

        if has(q, ["soil", "ph", "compost", "fym", "gypsum", "lime"]) {
            if crop == "Potato" {
                return BotMsg(role: .bot, text: """
                🥔 **Potato Soil Recommendations**
                • Soil Type: Sandy loam or loose loam; stony soils deform tubers.
                • Soil pH: Ideal range is 5.5 to 6.2. Alkaline soils promote common scab disease.
                """)
            } else if crop == "Tomato" {
                return BotMsg(role: .bot, text: """
                🍅 **Tomato Soil Recommendations**
                • Soil Type: Rich loam with high organic matter and excellent drainage.
                • Soil pH: Ideal range is 6.0 to 6.8.
                """)
            } else if crop == "Rice" {
                return BotMsg(role: .bot, text: """
                🌾 **Rice Soil Recommendations**
                • Soil Type: Clayey or clay-loam soils that hold water for long periods.
                • Soil pH: Prefers pH 5.5 to 6.5.
                """)
            } else {
                return BotMsg(role: .bot,
                    text: """
                    🌱 **Soil Science**
                    • pH <6.0 → Lime 2–4 t/hectare
                    • pH >8.0 → Gypsum 5–10 t/hectare
                    • FYM: 10–25 t/hectare before sowing
                    • Zinc Sulphate: 25 kg/hectare if Zn deficient
                    """,
                    chart: BotChart(title: "Optimal pH by Crop", bars: [
                        BotBar(label: "Potato",  value: 5.5, color: .orange),
                        BotBar(label: "Rice",    value: 6.0, color: AppTheme.greenLight),
                        BotBar(label: "Wheat",   value: 6.5, color: AppTheme.green),
                        BotBar(label: "Legumes", value: 7.0, color: .green)
                    ], unit: "pH"))
            }
        }

        if crop == "Tomato" {
            return BotMsg(role: .bot, text: """
            🍅 **Tomato Crop Care Overview**
            • Planting: Choose well-draining soil with 6-8 hours of direct sunlight. Set stakes or cages for vine support.
            • Watering: Apply 1-2 inches of water per week at the base of the plant to keep leaves dry.
            • Soil Health: Prefers soil pH between 6.0 and 6.8. Requires calcium to prevent blossom end rot.
            • Key Tip: Remove lower leaves to prevent soil-borne fungal spores from splashing onto foliage.
            """)
        } else if crop == "Maize" {
            return BotMsg(role: .bot, text: """
            🌽 **Maize Crop Care Overview**
            • Planting: Plant seeds 1-1.5 inches deep in blocks of at least 4 rows to ensure proper wind pollination.
            • Watering: Requires about 1 inch of water per week, critical during silking and tassel emergence.
            • Nutrients: Heavy feeder of nitrogen; apply nitrogen fertilizer during early vegetative growth.
            • Soil Health: Prefers loam soil with pH 6.0 - 7.0 and high organic matter.
            """)
        } else if crop == "Rice" {
            return BotMsg(role: .bot, text: """
            🌾 **Rice Crop Care Overview**
            • Planting: Start seeds in nurseries and transplant seedlings into puddled, flooded fields.
            • Water Management: Maintain constant shallow water depth (5-10 cm) during crop growth.
            • Soil: Prefers clayey soils that can retain water, with pH 5.5 - 6.5.
            • Key Tip: Drain the field 10-14 days before harvest to allow uniform grain ripening.
            """)
        } else if crop == "Potato" {
            return BotMsg(role: .bot, text: """
            🥔 **Potato Crop Care Overview**
            • Planting: Plant tuber pieces with 2-3 eyes in hilled rows, about 4 inches deep.
            • Soil Health: Prefers loose, sandy loam soil with pH 5.5 - 6.2 (helps prevent potato scab).
            • Hilling: Build soil mounds around stems as they grow to cover developing tubers from sunlight.
            • Watering: Keep soil evenly moist but not waterlogged to avoid tuber rot.
            """)
        } else if crop == "Wheat" {
            return BotMsg(role: .bot, text: """
            🌿 **Wheat Crop Care Overview**
            • Planting: Sow seeds in rows at 2-3 cm depth in well-prepared seedbeds during late autumn.
            • Irrigation: Critical irrigations at Crown Root Initiation (21 days), jointing, and flowering stages.
            • Fertilization: Apply recommended nitrogen, phosphorus, and potassium (NPK) doses.
            • Soil Health: Grows best in well-drained fertile clay-loam soils with pH 6.0 - 7.5.
            """)
        } else if crop == "Sugarcane" {
            return BotMsg(role: .bot, text: """
            🎋 **Sugarcane Crop Care Overview**
            • Planting: Plant healthy stem cuttings (setts) with 2-3 buds in furrows of 10-15 cm depth.
            • Watering: Requires high water availability; irrigate at intervals of 10-15 days in summer.
            • Nutrition: High nitrogen requirement along with potassium and phosphate.
            • Harvest: Crop matures in 10-12 months when the leaves turn yellow and canes sweeten.
            """)
        } else if crop == "Grape" {
            return BotMsg(role: .bot, text: """
            🍇 **Grape Care Overview**
            • Support: Grow vines on strong trellis systems and prune heavily during the dormant winter phase.
            • Soil Health: Deep, well-draining soils with pH 5.5 - 6.5 are ideal.
            • Watering: Deep watering at root zone; avoid overhead misting to protect against powdery mildew.
            • Key Tip: Ensure good air circulation through leaf thinning to prevent fungal infestations.
            """)
        }

        return BotMsg(role: .bot, text: """
        I want to give you an accurate answer. Please share:
        • **Crop name** (wheat, rice, tomato…)
        • **What you observe** (symptom, colour, pattern)
        • **Growth stage** if relevant
        """)
    }

    private func knowledgeReply(for query: String) -> BotMsg? {
        guard let match = offlineKnowledge.bestMatch(for: query) else { return nil }
        
        let diseaseDesc: String
        let preventionSteps: [String]
        
        switch match.name.lowercased() {
        case let x where x.contains("early blight"):
            diseaseDesc = "Early Blight is a common fungal disease affecting tomato and potato plants, caused by the pathogen Alternaria solani."
            preventionSteps = ["Practice crop rotation every 3 years", "Remove crop debris after harvest", "Use healthy, disease-free seedlings", "Mulch around the base of plants"]
        case let x where x.contains("late blight"):
            diseaseDesc = "Late Blight is a devastating fungal-like water mold disease affecting potato and tomato plants, caused by Phytophthora infestans."
            preventionSteps = ["Plant resistant crop varieties", "Destroy volunteer potato tubers", "Avoid overhead irrigation", "Ensure clean field sanitation"]
        case let x where x.contains("blast"):
            diseaseDesc = "Rice Blast is a highly destructive fungal disease affecting rice, caused by Magnaporthe oryzae, causing diamond-shaped leaf lesions."
            preventionSteps = ["Use blast-resistant cultivars", "Avoid excessive nitrogen fertilizers", "Clean seeds before planting", "Keep fields properly flooded"]
        case let x where x.contains("rust"):
            diseaseDesc = "Wheat Rust is a fungal disease affecting wheat leaves and stems, caused by Puccinia spp., forming orange-red spore pustules."
            preventionSteps = ["Grow rust-resistant wheat varieties", "Eliminate volunteer grass hosts", "Plant crops early in the season", "Maintain balanced NPK fertilizer application"]
        case let x where x.contains("powdery mildew"):
            diseaseDesc = "Powdery Mildew is a widespread fungal disease characterized by a white powdery coating on leaf surfaces, reducing photosynthesis."
            preventionSteps = ["Improve air circulation with correct spacing", "Grow plants in sunny locations", "Prune lower congested branches", "Use resistant crop varieties"]
        case let x where x.contains("leaf spot"):
            diseaseDesc = "Leaf Spot refers to circular spots or lesions on plant leaves, caused by various fungal or bacterial pathogens, leading to premature leaf drop."
            preventionSteps = ["Water the base of plants directly", "Collect and destroy fallen infected leaves", "Keep plants spaced apart", "Sanitize pruning tools"]
        default:
            diseaseDesc = "\(match.name) is a pathological condition that affects crop quality and yield."
            preventionSteps = ["Practice crop rotation", "Remove infected crop debris", "Use disease-free seeds", "Maintain proper plant spacing"]
        }
        
        var bodyText = """
        🌿 **\(match.name)**
        
        \(diseaseDesc)
        
        **Cause:** \(match.causes.joined(separator: ", "))
        
        **Symptoms:**
        """
        for sym in match.symptoms {
            bodyText += "\n• \(sym)"
        }
        
        bodyText += "\n\n**Risk Level:** \(match.severity)"
        
        bodyText += "\n\n**Treatment:**"
        for tr in match.treatments {
            bodyText += "\n• \(tr)"
        }
        
        bodyText += "\n\n**Prevention:**"
        for prv in preventionSteps {
            bodyText += "\n• \(prv)"
        }
        
        bodyText += "\n\n**Confidence:** 95%"
        
        return BotMsg(role: .bot, text: bodyText)
    }

    private func has(_ text: String, _ kw: [String]) -> Bool { kw.contains { text.contains($0) } }
    private func isGreeting(_ t: String) -> Bool {
        let g = ["hi", "hello", "hey", "good morning", "good evening", "namaste"]
        let t = t.trimmingCharacters(in: .whitespaces)
        return g.contains { t == $0 || t.hasPrefix("\",\" ") }
    }
}

private struct LocalDiseaseReference: Codable {
    let id: String
    let name: String
    let crops: [String]
    let symptoms: [String]
    let causes: [String]
    let treatments: [String]
    let tags: [String]
    let severity: String
}

private struct LocalKnowledgeStore {
    let entries: [LocalDiseaseReference]

    static func load() -> LocalKnowledgeStore {
        guard let url = Bundle.main.url(forResource: "Diseases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([LocalDiseaseReference].self, from: data) else {
            return LocalKnowledgeStore(entries: [])
        }
        return LocalKnowledgeStore(entries: entries)
    }

    func bestMatch(for query: String) -> LocalDiseaseReference? {
        let terms = query
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { $0.count > 2 }

        return entries
            .map { entry in
                let haystack = ([entry.name] + entry.crops + entry.symptoms + entry.causes + entry.tags)
                    .joined(separator: " ")
                    .lowercased()
                let score = terms.reduce(0) { partial, term in
                    partial + (haystack.contains(term) ? 1 : 0)
                }
                return (entry, score)
            }
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0.name < rhs.0.name }
                return lhs.1 > rhs.1
            }
            .first?
            .0
    }
}
