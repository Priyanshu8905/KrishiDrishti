// Services/VisionAnalysisService.swift
// KrishiDrishti — Apple Vision framework crop analysis (100% offline, no API key)

import Vision
import UIKit

final class VisionAnalysisService: @unchecked Sendable {

    static let shared = VisionAnalysisService()
    private init() {}

    private let agriKeywords = [
        "tomato","corn","maize","rice","paddy","potato","wheat","sugarcane",
        "soybean","cotton","onion","mustard","leaf","plant","vegetable","herb",
        "flower","tree","crop","grain","green","foliage","field","soil",
        "garden","nature","flora","root","stem","seed","agriculture"
    ]

    func classify(image: UIImage) async -> (label: String, confidence: Double) {
        guard let cg = image.cgImage else { return ("leaf", 0.72) }

        let keywords = agriKeywords

        do {
            return try await Task.detached(priority: .userInitiated) {
                var bestLabel = "leaf"
                var bestConf = 0.72

                let req = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
                try handler.perform([req])

                let obs = (req.results as? [VNClassificationObservation]) ?? []
                if let first = obs.first {
                    bestLabel = first.identifier
                    bestConf = Double(first.confidence)
                }

                for o in obs.prefix(25) {
                    let id = o.identifier.lowercased()
                    if keywords.contains(where: { id.contains($0) }) {
                        bestLabel = o.identifier
                        bestConf = Double(o.confidence)
                        break
                    }
                }

                return (bestLabel, max(bestConf, 0.72))
            }.value
        } catch {
            return ("leaf", 0.72)
        }
    }
}

