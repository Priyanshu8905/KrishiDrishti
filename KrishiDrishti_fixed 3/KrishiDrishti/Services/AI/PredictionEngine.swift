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

    private let specificKeywords = [
        "tomato", "corn", "maize", "rice", "paddy", "potato", "wheat", "sugarcane",
        "soybean", "cotton", "onion", "mustard", "grape", "vitis", "apple", "banana",
        "orange", "strawberry", "blueberry", "raspberry", "blackberry", "pear", "peach",
        "plum", "cherry", "mango", "papaya", "pineapple", "watermelon", "cantaloupe", "melon",
        "pepper", "eggplant", "chili", "cucumber", "pumpkin", "squash", "cabbage", "lettuce",
        "spinach", "broccoli", "cauliflower", "carrot", "radish", "garlic", "ginger", "pea",
        "bean", "lentil", "citrus", "lemon", "lime"
    ]

    private let genericKeywords = [
        "leaf", "plant", "vegetable", "herb", "flower", "tree", "crop", "grain",
        "green", "foliage", "field", "soil", "garden", "nature", "flora", "root",
        "stem", "seed", "agriculture"
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
            if specificKeywords.contains(where: { id.contains($0) }) {
                bestLabel = classification.label
                bestConf = classification.confidence
                break
            }
        }

        if bestLabel == nil {
            for classification in classifications {
                let id = classification.label.lowercased()
                if genericKeywords.contains(where: { id.contains($0) }) {
                    bestLabel = classification.label
                    bestConf = classification.confidence
                    break
                }
            }
        }

        if let label = bestLabel {
            let analysis = analyzeImageColors(image: image)
            return CropProblem.diagnose(
                label: label,
                confidence: bestConf,
                isHealthy: analysis.isHealthy,
                affectedArea: analysis.affectedArea,
                rotDetected: analysis.rotDetected
            )
        } else {
            return CropProblem.noCropDetected(confidence: classifications.first?.confidence ?? 0.0)
        }
    }

    private func analyzeImageColors(image: UIImage) -> (isHealthy: Bool, affectedArea: Double, rotDetected: Bool) {
        let targetSize = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        guard let cgImage = resized.cgImage,
              let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return (true, 0.0, false)
        }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let length = CFDataGetLength(pixelData)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        if bytesPerPixel < 3 { return (true, 0.0, false) }
        
        var greenCount = 0
        var yellowBrownCount = 0
        var darkCount = 0
        var totalPixels = 0
        
        for i in stride(from: 0, to: length - bytesPerPixel, by: bytesPerPixel) {
            let r = Int(data[i])
            let g = Int(data[i+1])
            let b = Int(data[i+2])
            
            totalPixels += 1
            
            if g > r && g > b && g > 45 && (g - r) > 10 {
                greenCount += 1
            } else if r > 60 && g > 50 && r > b && g > b && abs(r - g) < 40 && b < 130 {
                yellowBrownCount += 1
            } else if r < 75 && g < 75 && b < 75 && abs(r - g) < 25 && abs(g - b) < 25 {
                darkCount += 1
            }
        }
        
        if totalPixels == 0 { return (true, 0.0, false) }
        
        let unhealthyPixels = yellowBrownCount + darkCount
        let unhealthyRatio = Double(unhealthyPixels) / Double(totalPixels)
        let affectedArea = unhealthyRatio * 100.0
        let rotDetected = Double(darkCount) / Double(totalPixels) > 0.08
        let isHealthy = affectedArea < 8.0
        
        return (isHealthy, min(affectedArea * 1.5, 95.0), rotDetected)
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
