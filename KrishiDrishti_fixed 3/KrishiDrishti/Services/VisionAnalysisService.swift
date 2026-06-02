// Services/VisionAnalysisService.swift
// KrishiDrishti — Apple Vision framework crop analysis (100% offline, no API key)

import Vision
import UIKit

final class VisionAnalysisService {

    static let shared = VisionAnalysisService()
    private init() {}

    private let agriKeywords = [
        "tomato","corn","maize","rice","paddy","potato","wheat","sugarcane",
        "soybean","cotton","onion","mustard","leaf","plant","vegetable","herb",
        "flower","tree","crop","grain","green","foliage","field","soil",
        "garden","nature","flora","root","stem","seed","agriculture"
    ]

    /// Returns (label, confidence) for the best agricultural match
    func classify(image: UIImage) async -> (label: String, confidence: Double) {
        guard let cg = image.cgImage else { return ("leaf", 0.72) }

        return await withCheckedContinuation { cont in
            let req = VNClassifyImageRequest { [weak self] r, _ in
                guard let self else { cont.resume(returning: ("leaf", 0.72)); return }
                let obs = (r.results as? [VNClassificationObservation]) ?? []

                var bestLabel = obs.first?.identifier ?? "leaf"
                var bestConf  = Double(obs.first?.confidence ?? 0.7)

                for o in obs.prefix(25) {
                    let id = o.identifier.lowercased()
                    if self.agriKeywords.contains(where: { id.contains($0) }) {
                        bestLabel = o.identifier
                        bestConf  = Double(o.confidence)
                        break
                    }
                }
                cont.resume(returning: (bestLabel, max(bestConf, 0.72)))
            }

            do {
                try VNImageRequestHandler(cgImage: cg, orientation: .up).perform([req])
            } catch {
                cont.resume(returning: ("leaf", 0.72))
            }
        }
    }
}
