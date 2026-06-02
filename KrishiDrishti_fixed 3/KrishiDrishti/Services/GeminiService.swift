// Services/GeminiService.swift
// KrishiDrishti — Gemini integration supporting multimodal image diagnostics and JSON response parsing

import Foundation
import UIKit

final class GeminiService: Sendable {
    static let shared = GeminiService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("$(") && !apiKey.hasPrefix("YOUR_")
    }

    private struct Part: Codable {
        let text: String?
        let inlineData: InlineData?
    }

    private struct InlineData: Codable {
        let mimeType: String
        let data: String
    }

    private struct Content: Codable {
        let parts: [Part]
    }

    private struct Body: Codable {
        let contents: [Content]
    }

    private struct Candidate: Codable {
        struct ContentR: Codable {
            let parts: [Part]
        }
        let content: ContentR
    }

    private struct Response: Codable {
        let candidates: [Candidate]
    }

    // Dynamic response structure matching CropProblem fields
    private struct GeminiDiagnosis: Codable {
        let cropName: String
        let disease: String
        let scientificName: String
        let remedy: String
        let symptoms: [String]
        let severity: String
        let confidence: Double
        let affectedArea: Double
        let isHealthy: Bool
    }

    // MARK: - Image Analysis
    func analyzeCropImage(image: UIImage) async -> CropProblem? {
        guard isConfigured else { return nil }
        
        // Compress image to fit within payload limits
        guard let jpegData = image.jpegData(compressionQuality: 0.75) else { return nil }
        let base64Image = jpegData.base64EncodedString()

        let model = "gemini-1.5-flash"
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return nil }

        let systemPrompt = """
        You are a senior agronomist. Analyze this crop image.
        Return a valid JSON string containing the fields below. Do not wrap in ```json or include markdown formatting.
        {
          "cropName": "Tomato/Maize/Rice/Potato/Wheat/Sugarcane/Plant",
          "disease": "Disease name or 'No Disease Detected'",
          "scientificName": "Scientific name or 'N/A'",
          "remedy": "Numbered list of treatment actions",
          "symptoms": ["List of symptoms seen"],
          "severity": "Low/Medium/High",
          "confidence": 0.85,
          "affectedArea": 12.5,
          "isHealthy": false
        }
        If no crop or leaf is visible, return a JSON with cropName as "Unknown" and disease as "No crop detected".
        """

        let body = Body(contents: [
            Content(parts: [
                Part(text: systemPrompt, inlineData: nil),
                Part(text: nil, inlineData: InlineData(mimeType: "image/jpeg", data: base64Image))
            ])
        ])

        guard let bodyData = try? JSONEncoder().encode(body) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.timeoutInterval = 25.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { return nil }
            let result = try JSONDecoder().decode(Response.self, from: data)
            
            guard let textResponse = result.candidates.first?.content.parts.first?.text else { return nil }
            
            // Clean response to handle potential raw JSON wrapping
            let cleanJSON = textResponse
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let diagnosis = try JSONDecoder().decode(GeminiDiagnosis.self, from: cleanJSON.data(using: .utf8)!)
            
            let severityMapped: Severity
            switch diagnosis.severity.lowercased() {
            case "medium": severityMapped = .medium
            case "high":   severityMapped = .high
            default:       severityMapped = .low
            }

            return CropProblem(
                cropName: diagnosis.cropName,
                disease: diagnosis.disease,
                scientificName: diagnosis.scientificName,
                remedy: diagnosis.remedy,
                symptoms: diagnosis.symptoms,
                severity: severityMapped,
                confidence: diagnosis.confidence,
                affectedArea: diagnosis.affectedArea,
                isHealthy: diagnosis.isHealthy
            )
        } catch {
            return nil
        }
    }

    // MARK: - Text Chat
    func ask(system: String, user: String) async -> String? {
        guard isConfigured else { return nil }

        let model = "gemini-1.5-flash"
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { return nil }

        let combined = "\(system)\n\nFarmer question: \(user)"
        let body = Body(contents: [Content(parts: [Part(text: combined, inlineData: nil)])])
        guard let bodyData = try? JSONEncoder().encode(body) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.timeoutInterval = 15.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { return nil }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.candidates.first?.content.parts.first?.text
        } catch {
            return nil
        }
    }
}
