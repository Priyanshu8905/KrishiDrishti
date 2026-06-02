// Services/SarvamTTSService.swift
// KrishiDrishti — Sarvam AI Text-to-Speech (Hindi/Indian voices)
// Get FREE key at: https://sarvam.ai → Sign up → API Keys
// Add key to Info.plist → "SARVAM_API_KEY"
// Falls back to AVSpeechSynthesizer if key is missing (always works offline)

import AVFoundation
import Foundation

final class SarvamTTSService {

    static let shared = SarvamTTSService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SARVAM_API_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("$(") && !apiKey.hasPrefix("YOUR_")
    }

    // ── Sarvam API call ───────────────────────────────────────────────────────
    func synthesize(text: String, languageCode: String = "en-IN") async -> Data? {
        guard isConfigured else { return nil }
        guard let url = URL(string: "https://api.sarvam.ai/text-to-speech") else { return nil }

        let body: [String: Any] = [
            "inputs": [text],
            "target_language_code": languageCode,
            "speaker": "meera",
            "pace": 0.85,
            "loudness": 1.5,
            "speech_sample_rate": 22050,
            "enable_preprocessing": true,
            "model": "bulbul:v1"
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "api-subscription-key")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 10

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse,
                  http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let audios = json["audios"] as? [String],
                  let b64 = audios.first else { return nil }
            return Data(base64Encoded: b64)
        } catch {
            return nil
        }
    }
}
