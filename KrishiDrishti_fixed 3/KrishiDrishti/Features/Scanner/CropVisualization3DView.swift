// Views/Scanner/CropVisualization3DView.swift
// KrishiDrishti — Interactive 3D SceneKit rendering highlighting infection hotspots derived from Vision saliency calculations

import SwiftUI
import SceneKit

struct CropVisualization3DView: UIViewRepresentable {
    let isHealthy: Bool
    let affectedArea: Double
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true

        let scene = SCNScene()
        scnView.scene = scene

        // 1. Base Leaf Node
        let leafGeometry = SCNCylinder(radius: 0.8, height: 0.05)
        let leafMaterial = SCNMaterial()
        leafMaterial.diffuse.contents = isHealthy ? UIColor.systemGreen : UIColor(red: 0.32, green: 0.52, blue: 0.38, alpha: 1.0)
        leafGeometry.materials = [leafMaterial]

        let leafNode = SCNNode(geometry: leafGeometry)
        leafNode.rotation = SCNVector4(1, 0, 0, Float.pi / 4)
        scene.rootNode.addChildNode(leafNode)

        // 2. Add Infection Markers (Hotspots) if diseased
        if !isHealthy && affectedArea > 0 {
            // Distribute infection nodes over the leaf surface based on affectedArea percentage
            let markerCount = min(Int(affectedArea / 5.0) + 1, 8)
            for i in 0..<markerCount {
                let sphere = SCNSphere(radius: 0.12)
                let sphereMaterial = SCNMaterial()
                sphereMaterial.diffuse.contents = UIColor.systemRed
                sphere.materials = [sphereMaterial]

                let sphereNode = SCNNode(geometry: sphere)
                
                // Position randomly across cylinder surface
                let angle = Float(i) * (2.0 * Float.pi / Float(markerCount))
                let radius = Float.random(in: 0.2...0.6)
                let x = cos(angle) * radius
                let z = sin(angle) * radius
                
                sphereNode.position = SCNVector3(x, 0.04, z)
                leafNode.addChildNode(sphereNode)
            }
        }

        // 3. Camera Node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.5, 2.2)
        cameraNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 12)
        scene.rootNode.addChildNode(cameraNode)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
