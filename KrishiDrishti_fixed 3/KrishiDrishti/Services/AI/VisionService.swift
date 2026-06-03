// Services/AI/VisionService.swift
// KrishiDrishti — Handles OCR (Text Recognition) and Object/Leaf detection using Apple Vision framework

import Vision
import UIKit

protocol VisionServiceProtocol: Sendable {
    func recognizeText(in image: UIImage) async throws -> [String]
    func detectObjects(in image: UIImage) async throws -> [CGRect]
}

final class VisionService: VisionServiceProtocol, @unchecked Sendable {
    init() {}

    func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }

        return try await Task.detached(priority: .userInitiated) {
            var recognizedStrings: [String] = []
            var recognitionError: Error?

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    recognitionError = error
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }

                recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            if let error = recognitionError {
                throw error
            }

            return recognizedStrings
        }.value
    }

    func detectObjects(in image: UIImage) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }

        return try await Task.detached(priority: .userInitiated) {
            var detectedBounds: [CGRect] = []
            var detectionError: Error?

            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    detectionError = error
                    return
                }

                guard let observations = request.results as? [VNSaliencyImageObservation],
                      let salObs = observations.first else {
                    return
                }

                detectedBounds = salObs.salientObjects?.map { $0.boundingBox } ?? []
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            if let error = detectionError {
                throw error
            }

            return detectedBounds
        }.value
    }
}

