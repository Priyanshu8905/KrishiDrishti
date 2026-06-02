// Services/GeminiService.swift
// KrishiDrishti — Google Gemini 1.5 Flash (FREE: 1500 requests/day)
// Get free key at: https://aistudio.google.com → Get API Key
// Add key to Info.plist → "GEMINI_API_KEY"

import Foundation

final class GeminiService {

    static let shared = GeminiService()
    private init() {}

    // ── Fetch key from Info.plist (set in Package.swift) ──────────────────────
    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("$(") && !apiKey.hasPrefix("YOUR_")
    }

    // ── Models ────────────────────────────────────────────────────────────────
    private struct Part: Codable    { let text: String }
    private struct Content: Codable { let parts: [Part] }
    private struct Body: Codable    { let contents: [Content] }
    private struct Candidate: Codable {
        struct ContentR: Codable { let parts: [Part] }
        let content: ContentR
    }
    private struct Response: Codable { let candidates: [Candidate] }

    // ── Main call ─────────────────────────────────────────────────────────────
    func ask(
        system: String,
        user: String
    ) async -> String? {
        guard isConfigured else { return nil }

        let model = "gemini-1.5-flash"
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return nil }

        let combined = "\(system)\n\nFarmer question: \(user)"
        let body = Body(contents: [Content(parts: [Part(text: combined)])])
        guard let bodyData = try? JSONEncoder().encode(body) else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData
        req.timeoutInterval = 10

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return nil }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.candidates.first?.content.parts.first?.text
        } catch {
            return nil
        }
    }
}
