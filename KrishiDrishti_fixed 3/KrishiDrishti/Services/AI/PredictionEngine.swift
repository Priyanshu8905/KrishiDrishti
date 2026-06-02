// Services/AI/PredictionEngine.swift
// KrishiDrishti — Local AI prediction router combining CoreML, Vision, and NaturalLanguage analysis

import UIKit
import NaturalLanguage

protocol PredictionEngineProtocol: Sendable {
    func predictCropProblem(from image: UIImage) async throws -> CropProblem
    func analyzeSentiment(of text: String) -> String
}

final class PredictionEngine: PredictionEngineProtocol {
    private let coreMLService: CoreMLServiceProtocol
    private let visionService: VisionServiceProtocol

    private let agriculturalKeywords = [
        "tomato", "corn", "maize", "rice", "paddy", "potato", "wheat", "sugarcane",
        "soybean", "cotton", "onion", "mustard", "leaf", "plant", "vegetable", "herb",
        "flower", "tree", "crop", "grain", "green", "foliage", "field", "soil",
        "garden", "nature", "flora", "root", "stem", "seed", "agriculture"
    ]

    init(coreMLService: CoreMLServiceProtocol = CoreMLService(),
         visionService: VisionServiceProtocol = VisionService()) {
        self.coreMLService = coreMLService
        self.visionService = visionService
    }

    func predictCropProblem(from image: UIImage) async throws -> CropProblem {
        let classifications = try await coreMLService.performClassification(image: image)

        var bestLabel: String? = nil
        var bestConf = 0.0

        for classification in classifications {
            let id = classification.label.lowercased()
            if agriculturalKeywords.contains(where: { id.contains($0) }) {
                bestLabel = classification.label
                bestConf = classification.confidence
                break
            }
        }

        if let label = bestLabel {
            return CropProblem.diagnose(label: label, confidence: bestConf)
        } else {
            return CropProblem.noCropDetected(confidence: classifications.first?.confidence ?? 0.0)
        }
    }

    func analyzeSentiment(of text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentimentTag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)

        guard let scoreString = sentimentTag?.rawValue, let score = Double(scoreString) else {
            return "neutral"
        }

        if score > 0.15 {
            return "positive"
        } else if score < -0.15 {
            return "negative"
        } else {
            return "neutral"
        }
    }
}
