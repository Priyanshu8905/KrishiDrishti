// Services/AI/CoreMLService.swift
// KrishiDrishti — Handles local CoreML model interaction and predictions

import CoreML
import Vision
import UIKit

protocol CoreMLServiceProtocol: Sendable {
    func performClassification(image: UIImage) async throws -> [(label: String, confidence: Double)]
}

final class CoreMLService: CoreMLServiceProtocol {
    init() {}

    func performClassification(image: UIImage) async throws -> [(label: String, confidence: Double)] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "CoreMLService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.prefix(5).map { obs in
                    (label: obs.identifier, confidence: Double(obs.confidence))
                }
                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
