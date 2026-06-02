// Services/AR/ARViewContainer.swift
// KrishiDrishti — SwiftUI container displaying the AR session with plane interaction support

import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: ARSessionManager

    init(sessionManager: ARSessionManager) {
        self.sessionManager = sessionManager
    }

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = sessionManager.session
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.showsStatistics = false

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            let location = gesture.location(in: arView)

            let results = arView.hitTest(location, types: [.existingPlaneUsingExtent])
            guard let hitResult = results.first else { return }

            let sphere = SCNSphere(radius: 0.05)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemGreen
            sphere.materials = [material]

            let node = SCNNode(geometry: sphere)
            let transform = hitResult.worldTransform
            node.position = SCNVector3(transform.columns.3.x, transform.columns.3.y + 0.05, transform.columns.3.z)

            arView.scene.rootNode.addChildNode(node)

            Task { @MainActor in
                self.parent.sessionManager.anchorPlaced = true
            }
        }
    }
}
