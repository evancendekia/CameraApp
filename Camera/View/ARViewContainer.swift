//import SwiftUI
//import ARKit
//
//struct ARViewContainer: UIViewRepresentable {
//    func updateUIView(_ uiView: ARSCNView, context: Context) {
//        let arView = ARSCNView(frame: .zero)
//        context.coordinator.arView = arView
//        arView.delegate = context.coordinator
//        // Configure and run the AR session as needed
////        return arView
//    }
//    
//    
//    let session = AVCaptureSession()
//    var photoOutput = AVCapturePhotoOutput()
//    var currentCameraPosition: AVCaptureDevice.Position = .back
//    
//    @Binding var faces: [FaceData]
//    @Binding var faceID: UUID
//    var viewModel: ARViewModel
//
//    func makeCoordinator() -> Coordinator {
//        let coordinator = Coordinator(faces: $faces, faceID: $faceID)
//        viewModel.coordinator = coordinator
//        return coordinator
//    }
//
//    func makeUIView(context: Context) -> ARSCNView {
//        
//        let arView = ARSCNView(frame: .zero)
//        context.coordinator.arView = arView
//        print("✅ ARView assigned to ARViewModel")
//        arView.delegate = context.coordinator
//
//        if ARFaceTrackingConfiguration.isSupported && ARFaceTrackingConfiguration.supportsWorldTracking {
//            let configuration = ARFaceTrackingConfiguration()
//            configuration.maximumNumberOfTrackedFaces = 3
//            configuration.isLightEstimationEnabled = true
//            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//        }
////        if ARFaceTrackingConfiguration.isSupported && ARFaceTrackingConfiguration.supportsWorldTracking {
////            let configuration = ARWorldTrackingConfiguration()
//////            let configuration = ARFaceTrackingConfiguration()
//////            configuration.maximumNumberOfTrackedFaces = 3
////            configuration.isLightEstimationEnabled = true
////            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
////        }
//
//        return arView
//    }
//
//    func updateUIView(_ uiView: ARSCNView, context: Context) -> ARSCNView {
//        let arView = ARSCNView(frame: .zero)
//        context.coordinator.arView = arView
//        arView.delegate = context.coordinator
//        // Configure and run the AR session as needed
//        return arView
//    }
//
//    class Coordinator: NSObject, ARSCNViewDelegate {
//        var arView: ARSCNView?
//        @Binding var faces: [FaceData]
//        @Binding var faceID: UUID
//        private var cleanupTimer: Timer?
//        private var hasCapturedSmile: Bool = false
//        
//
//        init(faces: Binding<[FaceData]>, faceID: Binding<UUID>) {
//            _faces = faces
//            _faceID = faceID
//            super.init()
//            startCleanupTimer()
//            
//        }
//        
//        deinit {
//            cleanupTimer?.invalidate()
//        }
//
//        private func startCleanupTimer() {
//            cleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//                self?.removeStaleFaces()
//            }
//        }
//
//        private func removeStaleFaces() {
//            let now = Date()
////            let timeout: TimeInterval = 2.0 // Waktu dalam detik
//            let timeout: TimeInterval = 0.5 // Waktu dalam detik
//            DispatchQueue.main.async {
//                self.faces.removeAll { now.timeIntervalSince($0.lastSeen) > timeout }
//            }
//        }
//
//        
//        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
//            guard let faceAnchor = anchor as? ARFaceAnchor else { return }
//            let faceID = faceAnchor.identifier
//            
//            print("Face ID: \(faceID) removed")
//
//            DispatchQueue.main.async {
//                self.faces.removeAll { $0.id == faceID }
//            }
//        }
//        
//        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//            guard anchor is ARFaceAnchor else { return nil }
//            
//            print("Face ID: \(faceID) detected")
//            // Create a plane geometry to represent the square
//            let plane = SCNPlane(width: 0.15, height: 0.15)
//            plane.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.9)
//            plane.firstMaterial?.isDoubleSided = true
//
////            // Create a node with the plane geometry
//            let planeNode = SCNNode(geometry: plane)
//            planeNode.position = SCNVector3(0, 0, 0.1) // Position the plane slightly in front of the face
//            planeNode.eulerAngles.x = -.pi / 2  // Rotate to face the camera
//
//            // Create a parent node to hold the plane
//            let parentNode = SCNNode()
////            parentNode.addChildNode(planeNode)
//
//            return parentNode
//        }
////        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
////            guard let faceAnchor = anchor as? ARFaceAnchor else { return }
////
////            // Update the position of the node to match the face anchor
////            let transform = faceAnchor.transform
////            node.transform = SCNMatrix4(transform)
////
////            // Existing expression detection logic...
////        }
//
//        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//            guard let faceAnchor = anchor as? ARFaceAnchor else { return }
//            
//            let faceID = anchor.identifier
//            
//            let transform = faceAnchor.transform
//            node.transform = SCNMatrix4(transform)
//
//            let blendShapes = faceAnchor.blendShapes
//
//            let smileLeft = blendShapes[.mouthSmileLeft]?.floatValue ?? 0.0
//            let smileRight = blendShapes[.mouthSmileRight]?.floatValue ?? 0.0
//            let frownLeft = blendShapes[.mouthFrownLeft]?.floatValue ?? 0.0
//            let frownRight = blendShapes[.mouthFrownRight]?.floatValue ?? 0.0
//            let browDownLeft = blendShapes[.browDownLeft]?.floatValue ?? 0.0
//            let browDownRight = blendShapes[.browDownRight]?.floatValue ?? 0.0
//
//            let smileAverage = (smileLeft + smileRight) / 2.0
//            let frownAverage = (frownLeft + frownRight) / 2.0
//            let browDownAverage = (browDownLeft + browDownRight) / 2.0
//
//            var expression = ""
////            if smileAverage > 0.5 {
////               expression = "Smile"
////               if !hasCapturedSmile {
////                   hasCapturedSmile = true
////                   captureSnapshot()
////               }
////            } else {
////            }
//            if smileAverage > 0.5 {
////                    self.expression = "😊"
//                expression = "Smile"
//                if !hasCapturedSmile {
//                    hasCapturedSmile = true
////                    captureSnapshot()
//                }
//            } else if frownAverage > 0.5 {
////                    self.expression = "😠"
//                expression = "Sad"
//                hasCapturedSmile = false
//            } else if browDownAverage > 0.5 {
////                    self.expression = "😢"
//                expression = "Upset"
//                hasCapturedSmile = false
//            } else {
////                    self.expression = "😐"
////                expression = "Flat"
//                expression = "Neutral"
//                hasCapturedSmile = false
//            }
//            
//            
//            DispatchQueue.main.async {
//                if let index = self.faces.firstIndex(where: { $0.id == faceID }) {
//                    self.faces[index].expression = expression
//                    self.faces[index].lastSeen = Date()
//                } else {
//                    self.faces.append(FaceData(id: faceID, expression: expression, lastSeen: Date()))
//                }
//            }
////            print("Face ID: \(faceID) updated (\(expression))")
////            DispatchQueue.main.async {
////
//////                self.faceID = faceID
//////                self.expression = expresion
////
////                if let index = self.faces.firstIndex(where: { $0.id == faceID }) {
////                    self.faces[index].expression = expression
////                    self.faces[index].lastSeen = Date()
////                } else {
////                    self.faces.append(FaceData(id: faceID, expression: expression, lastSeen: Date()))
////                }
////            }
////            DispatchQueue.main.async {
////
////           }
//        }
//        func captureSnapshot() {
//           guard let arView = arView else { return }
//           let image = arView.snapshot()
//           UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
//        }
//
//        @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//           if let error = error {
//               print("Error saving photo: \(error.localizedDescription)")
//           } else {
//               print("Photo saved successfully.")
//           }
//        }
//    }
//}

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var faces: [FaceData]
    @Binding var faceID: UUID
    var viewModel: ARViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        viewModel.arView = arView
        print("✅ ARView assigned to ViewModel")

        guard ARFaceTrackingConfiguration.isSupported else {
            print("❌ Face tracking not supported on this device.")
            return arView
        }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true

        // ✅ Enable multi-face tracking if supported
        if ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces > 1 {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
            print("👥 Multi-face tracking enabled: \(configuration.maximumNumberOfTrackedFaces) faces")
        } else {
            configuration.maximumNumberOfTrackedFaces = 1
        }

        arView.session.delegate = context.coordinator
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, faces: $faces, faceID: $faceID)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        private var cleanupTimer: Timer?
        @Binding var faces: [FaceData]
        @Binding var faceID: UUID

        init(_ parent: ARViewContainer,faces: Binding<[FaceData]>, faceID: Binding<UUID>) {
            _faces = faces
            _faceID = faceID
            self.parent = parent
            super.init()
            startCleanupTimer()
        }


        private func startCleanupTimer() {
            cleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.removeStaleFaces()
            }
        }

        private func removeStaleFaces() {
            let now = Date()
//            let timeout: TimeInterval = 2.0 // Waktu dalam detik
            let timeout: TimeInterval = 0.2 // Waktu dalam detik
            DispatchQueue.main.async {
                self.faces.removeAll { now.timeIntervalSince($0.lastSeen) > timeout }
            }
        }
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let faceAnchor = anchor as? ARFaceAnchor else { continue }

                let smileLeft = faceAnchor.blendShapes[.mouthSmileLeft]?.floatValue ?? 0.0
                let smileRight = faceAnchor.blendShapes[.mouthSmileRight]?.floatValue ?? 0.0
                let isSmiling = (smileLeft + smileRight) / 2.0 > 0.5
                let expression = isSmiling ? "Smiling" : "Neutral"

                DispatchQueue.main.async {
                    let faceUUID = anchor.identifier

                    if let index = self.parent.faces.firstIndex(where: { $0.id == faceUUID }) {
                        self.parent.faces[index].expression = expression
                        self.parent.faces[index].lastSeen = Date()
                    } else {
                        let newFace = FaceData(id: faceUUID, expression: expression, lastSeen: Date())
                        self.parent.faces.append(newFace)
                    }
                }
            }
        }
    }
}

