// Services/AI/CoreMLService.swift
// KrishiDrishti — Handles local CoreML model interaction and predictions

import CoreML
import Vision
import UIKit

protocol CoreMLServiceProtocol: Sendable {
    func performClassification(image: UIImage) async throws -> [(label: String, confidence: Double)]
}

final class CoreMLService: CoreMLServiceProtocol, @unchecked Sendable {
    init() {}

    func performClassification(image: UIImage) async throws -> [(label: String, confidence: Double)] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "CoreMLService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }

        return try await Task.detached(priority: .userInitiated) {
            var classificationResults: [(label: String, confidence: Double)] = []
            var classificationError: Error?

            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    classificationError = error
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    return
                }

                classificationResults = observations.prefix(20).map { obs in
                    (label: obs.identifier, confidence: Double(obs.confidence))
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            if let error = classificationError {
                throw error
            }

            return classificationResults
        }.value
    }
}
