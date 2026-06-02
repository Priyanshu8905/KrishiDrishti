// ViewModels/KrishiBotViewModel.swift
// KrishiDrishti — KrishiBot AI (Gemini 1.5 Flash free tier + offline expert engine)

import SwiftUI
import Vision

// MARK: - Message model
struct BotMsg: Identifiable {
    let id   = UUID()
    let role: BotRole
    var text: String
    var image: UIImage?
    var chart: BotChart?
}
enum BotRole { case user, bot }

struct BotChart: Identifiable {
    let id    = UUID()
    let title: String
    let bars:  [BotBar]
    let unit:  String
}
struct BotBar: Identifiable {
    let id    = UUID()
    let label: String
    let value: Double
    let color: Color
}

// MARK: - ViewModel
@MainActor
final class KrishiBotVM: ObservableObject {

    @Published var messages: [BotMsg] = []
    @Published var input:    String   = ""
    @Published var thinking: Bool     = false

    var currentWeather: WeatherData?
    var farmerCrops:    [String] = []
    var farmerName:     String   = ""
    private let offlineKnowledge = LocalKnowledgeStore.load()

    // Gemini system prompt
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

    init() {
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

    // MARK: - Photo analysis
    func analyzePhoto(_ img: UIImage) {
        messages.append(BotMsg(role: .user, text: "📷 Photo submitted for analysis:", image: img))
        thinking = true
        Task {
            let (label, conf) = await VisionAnalysisService.shared.classify(image: img)
            let reply = photoReply(label: label, conf: conf)
            self.thinking = false
            self.messages.append(reply)
        }
    }

    private func photoReply(label: String, conf: Double) -> BotMsg {
        let l = label.lowercased()
        let pct = min(Int(conf * 100), 99)
        let w   = currentWeather
        if l.contains("tomato")                          { return cropCard(.tomato,    pct: pct, w: w) }
        if l.contains("corn") || l.contains("maize")    { return cropCard(.maize,     pct: pct, w: w) }
        if l.contains("rice") || l.contains("paddy")    { return cropCard(.rice,      pct: pct, w: w) }
        if l.contains("potato")                         { return cropCard(.potato,    pct: pct, w: w) }
        if l.contains("wheat")                          { return cropCard(.wheat,     pct: pct, w: w) }
        if l.contains("sugarcane")                      { return cropCard(.sugarcane, pct: pct, w: w) }
        if l.contains("soil") || l.contains("dirt")     { return soilCard(pct: pct) }
        if l.contains("leaf") || l.contains("plant") || l.contains("green") {
            return BotMsg(role: .bot, text: "🌿 **Plant/leaf detected** (\(pct)%)\n\nFor precise diagnosis, describe the symptoms you see.")
        }
        return BotMsg(role: .bot, text: "🔍 Detected: *\(label)* (\(pct)%)\n\nCrop not clearly identified. Type the crop name and symptom below.")
    }

    // MARK: - Send text
    func sendText() {
        let q = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        messages.append(BotMsg(role: .user, text: q))
        input = ""; thinking = true

        Task {
            // Try Gemini first (free 1500/day), fall back to offline engine
            if GeminiService.shared.isConfigured,
               let ai = await GeminiService.shared.ask(system: geminiSystem, user: q) {
                self.thinking = false
                self.messages.append(BotMsg(role: .bot, text: ai))
            } else {
                let local = self.expertReply(q)
                self.thinking = false
                self.messages.append(local)
            }
        }
    }

    // MARK: - Offline expert engine
    private func expertReply(_ raw: String) -> BotMsg {
        let q = raw.lowercased()
        let w = currentWeather
        let name = farmerName.isEmpty ? "Farmer" : farmerName

        if isGreeting(q) {
            return BotMsg(role: .bot, text: "Hello \(name)! 👋 How can I help you today?")
        }
        if has(q, ["weather","temperature","humidity","rain","forecast"]) {
            if let w {
                return BotMsg(role: .bot, text: """
                🌤️ **Weather — \(w.locationName)**
                🌡️ **\(String(format:"%.1f",w.temperature))°C** · 💧 **\(w.humidity)%** · 💨 **\(Int(w.windSpeed)) km/h**
                **Disease Risk:** \(w.riskLabel)
                **Source:** \(w.sourceLabel)
                **Advisory:** \(w.advisory(for: farmerCrops))
                """)
            }
            return BotMsg(role: .bot, text: "🌤️ Weather is still loading. Please wait a moment.")
        }
        if let reference = knowledgeReply(for: q) {
            return reference
        }
        if has(q, ["early blight","alternaria"]) {
            return BotMsg(role: .bot, text: """
            🍅 **Early Blight — *Alternaria solani***
            • Concentric rings on lower leaves, yellow halo around spots
            • Temperature 24–29°C, humidity >85%
            **Treatment:** Mancozeb 75 WP — 2 g/litre every 7 days
            OR Azoxystrobin 23 SC — 1 ml/litre for active infection
            Remove infected leaves. Avoid overhead irrigation.
            """)
        }
        if has(q, ["late blight","phytophthora"]) {
            return BotMsg(role: .bot, text: """
            🥔 **Late Blight — *Phytophthora infestans***
            • Water-soaked irregular spots, white growth under leaves
            **Treatment:** Cymoxanil + Mancozeb — 2.5 g/litre every 5–7 days
            Burn infected material. Never compost.
            \(w.map { $0.humidity > 80 ? "\n🚨 Humidity \($0.humidity)% — HIGH RISK. Spray immediately." : "" } ?? "")
            """)
        }
        if has(q, ["bacterial blight","blb","xanthomonas"]) {
            return BotMsg(role: .bot, text: """
            🌾 **Bacterial Leaf Blight — Rice**
            • Yellow stripes on leaf margins → turn white/grey
            **Treatment:**
            1. Drain field immediately
            2. Copper Oxychloride 50 WP — 3 g/litre
            3. Stop all nitrogen fertilizer
            ⚠️ No fungicide works — this is bacterial.
            """)
        }
        if has(q, ["fertilizer","urea","dap","npk","nitrogen"]) {
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
        if has(q, ["pest","aphid","thrips","stem borer","armyworm"]) {
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
        if has(q, ["soil","ph","compost","fym","gypsum"]) {
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

        // Crop cards fallback
        if has(q, ["tomato"])    { return cropCard(.tomato,    pct: 90, w: w) }
        if has(q, ["maize","corn"]) { return cropCard(.maize, pct: 90, w: w) }
        if has(q, ["rice","paddy"]) { return cropCard(.rice,  pct: 90, w: w) }
        if has(q, ["potato"])    { return cropCard(.potato,    pct: 90, w: w) }
        if has(q, ["wheat"])     { return cropCard(.wheat,     pct: 90, w: w) }
        if has(q, ["sugarcane"]) { return cropCard(.sugarcane, pct: 90, w: w) }

        return BotMsg(role: .bot, text: """
        I want to give you an accurate answer. Please share:
        • **Crop name** (wheat, rice, tomato…)
        • **What you observe** (symptom, colour, pattern)
        • **Growth stage** if relevant
        """)
    }

    // MARK: - Crop cards
    private enum CropType { case tomato, maize, rice, potato, wheat, sugarcane }

    private func cropCard(_ crop: CropType, pct: Int, w: WeatherData?) -> BotMsg {
        let wn = w.map { "\n🌡️ \(Int($0.temperature))°C · \($0.humidity)% · \($0.condition)" } ?? ""
        switch crop {
        case .tomato:
            return BotMsg(role: .bot,
                text: "🍅 **Tomato** — Disease Overview\(wn)\n1. Early Blight → Mancozeb 2 g/litre\n2. Late Blight → Cymoxanil+Mancozeb 2.5 g/litre\n3. Mosaic Virus → remove plants (no cure)\n\(w.map{$0.humidity>75 ? "\n⚠️ High humidity — elevated fungal risk." : ""} ?? "")",
                chart: BotChart(title: "Tomato Disease Frequency (%)", bars: [
                    BotBar(label:"Early Blight", value:75, color:.orange),
                    BotBar(label:"Late Blight",  value:55, color:.red),
                    BotBar(label:"Mosaic Virus", value:30, color:.yellow)
                ], unit: "%"))
        case .maize:
            return BotMsg(role: .bot,
                text: "🌽 **Maize** — Disease Overview\(wn)\n1. NLB → Propiconazole 1 ml/litre\n2. Fall Armyworm → Emamectin Benzoate 0.5 g/litre\n3. Stalk Rot → resistant hybrids",
                chart: BotChart(title: "Maize Threats (%)", bars: [
                    BotBar(label:"NLB", value:65, color:.orange),
                    BotBar(label:"FAW", value:55, color:.red),
                    BotBar(label:"Stalk Rot", value:40, color:.brown)
                ], unit: "%"))
        case .rice:
            return BotMsg(role: .bot, text: "🌾 **Rice** — Disease Overview\(wn)\n1. BLB → drain + Copper Oxychloride 3 g/litre\n2. Blast → Tricyclazole 75 WP 0.6 g/litre\n3. Sheath Blight → Hexaconazole 1 ml/litre")
        case .potato:
            return BotMsg(role: .bot, text: "🥔 **Potato** — Disease Overview\(wn)\n1. Late Blight → Cymoxanil+Mancozeb 2.5 g/litre every 5–7 days\n2. Early Blight → Mancozeb 2 g/litre every 7 days\n\(w.map{$0.humidity>80 ? "\n🚨 SEVERE risk — Spray immediately." : ""} ?? "")")
        case .wheat:
            return BotMsg(role: .bot,
                text: "🌿 **Wheat** — Disease Overview\(wn)\n1. Yellow Rust → Propiconazole 1 ml/litre\n2. Powdery Mildew → Tebuconazole 1 ml/litre",
                chart: BotChart(title: "Wheat Yield Loss (%)", bars: [
                    BotBar(label:"Yellow Rust",    value:40, color:.yellow),
                    BotBar(label:"Powdery Mildew", value:20, color:.gray),
                    BotBar(label:"Loose Smut",     value:15, color:.brown)
                ], unit: "%"))
        case .sugarcane:
            return BotMsg(role: .bot, text: "🎋 **Sugarcane** — Disease Overview\(wn)\n1. Red Rot → burn affected stools\n2. Smut → hot water treat seed 52°C 30 min\n3. Top Shoot Borer → Chlorpyrifos 2 ml/litre")
        }
    }

    private func soilCard(pct: Int) -> BotMsg {
        BotMsg(role: .bot,
            text: "🌱 **Soil detected** (\(pct)%)\n• pH <6 → Lime 2–4 t/hectare\n• pH >8 → Gypsum 5–10 t/hectare\n• Zinc Sulphate 25 kg/hectare if Zn deficient",
            chart: BotChart(title: "Micronutrient Doses (kg/ha)", bars: [
                BotBar(label: "Zinc Sulphate", value: 25, color: AppTheme.green),
                BotBar(label: "Borax",         value: 10, color: AppTheme.amber),
                BotBar(label: "Ferrous Sulph", value: 25, color: AppTheme.greenLight)
            ], unit: "kg"))
    }

    private func knowledgeReply(for query: String) -> BotMsg? {
        guard let match = offlineKnowledge.bestMatch(for: query) else { return nil }
        return BotMsg(role: .bot, text: """
        📚 **Offline Reference: \(match.name)**
        **Crop:** \(match.crops.joined(separator: ", "))
        **Severity:** \(match.severity)
        **Symptoms:** \(match.symptoms.joined(separator: ", "))
        **Cause:** \(match.causes.joined(separator: ", "))
        **Treatment:** \(match.treatments.joined(separator: ", "))
        """)
    }

    // MARK: - Helpers
    private func has(_ text: String, _ kw: [String]) -> Bool { kw.contains { text.contains($0) } }
    private func isGreeting(_ t: String) -> Bool {
        let g = ["hi","hello","hey","good morning","good evening","namaste"]
        let t = t.trimmingCharacters(in: .whitespaces)
        return g.contains { t == $0 || t.hasPrefix("\($0) ") }
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
