import Foundation
import RealityKit
import ARKit
import SwiftUI

class ARViewModel: ObservableObject {
//    var coordinator: ARViewContainer.Coordinator?
    
    var arView: ARView?

    func captureSnapshot(completion: @escaping (UIImage?) -> Void) {
         guard let arView = arView else {
             print("ARView not initialized")
             completion(nil)
             return
         }
        arView.snapshot(saveToHDR: false) { image in
            print("Snapshot captured: \(image != nil)")
            DispatchQueue.main.async {
                completion(image)
            }
        }

     }
    func restartSession() {
            guard let arView = arView else { return }

            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces

            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("🔄 AR session restarted")
        }
}
