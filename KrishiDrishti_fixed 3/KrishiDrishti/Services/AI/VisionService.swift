// Services/AI/VisionService.swift
// KrishiDrishti — Handles OCR (Text Recognition) and Object/Leaf detection using Apple Vision framework

import Vision
import UIKit

protocol VisionServiceProtocol: Sendable {
    func recognizeText(in image: UIImage) async throws -> [String]
    func detectObjects(in image: UIImage) async throws -> [CGRect]
}

final class VisionService: VisionServiceProtocol {
    init() {}

    func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let transcript = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                continuation.resume(returning: transcript)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func detectObjects(in image: UIImage) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNSaliencyImageObservation],
                      let salObs = observations.first else {
                    continuation.resume(returning: [])
                    return
                }

                let bounds = salObs.salientObjects?.map { $0.boundingBox } ?? []
                continuation.resume(returning: bounds)
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
