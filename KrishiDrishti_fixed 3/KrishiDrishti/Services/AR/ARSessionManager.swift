// Services/AR/ARSessionManager.swift
// KrishiDrishti — Configures and manages the ARKit tracking session for farm layout mapping

import ARKit
import RealityKit
import Combine

@MainActor
final class ARSessionManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var sessionMessage: String = "Initializing AR..."
    @Published var anchorPlaced = false

    let session = ARSession()

    override init() {
        super.init()
        session.delegate = self
    }

    func startSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            sessionMessage = "ARKit is not supported on this device"
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true

        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sessionMessage = "Point camera at field or ground to scan"
    }

    func pauseSession() {
        session.pause()
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        trackingState = camera.trackingState
        switch camera.trackingState {
        case .notAvailable:
            sessionMessage = "AR tracking not available"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                sessionMessage = "Too much movement. Slow down."
            case .insufficientFeatures:
                sessionMessage = "Too dark or flat surface. Find texture."
            case .initializing:
                sessionMessage = "Scanning area..."
            case .relocalizing:
                sessionMessage = "Relocalizing AR session..."
            @unknown default:
                sessionMessage = "Limited tracking"
            }
        case .normal:
            sessionMessage = "AR tracking active. Tap to place virtual marker."
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionMessage = "AR session error: \(error.localizedDescription)"
    }
}
