//
//  Coordinator.swift
//  Camera
//
//  Created by acqmal on 5/7/25.
//

import SwiftUI
import RealityKit
import ARKit

class Coordinator: NSObject, ARSessionDelegate {
    var parent: ARViewContainer
    private var cleanupTimer: Timer?
    @Binding var faces: [FaceData]
    @Binding var faceID: UUID
    @Binding var isExpressionDetectionEnabled: Bool

    init(_ parent: ARViewContainer,faces: Binding<[FaceData]>, faceID: Binding<UUID>, isExpressionDetectionEnabled: Binding<Bool>) {
        _faces = faces
        _faceID = faceID
        _isExpressionDetectionEnabled = isExpressionDetectionEnabled
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
        guard isExpressionDetectionEnabled else { return }
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
    
//    func savePickerController(_ image: UIImage) {
//        let filePath =
//        let let data =
//    }
    
    func saveImageWithImageData(filename : String, data: NSData, properties: NSDictionary) {
        let imageRef: CGImageSource = CGImageSourceCreateWithData((data as CFData), nil)!
        let uti: CFString = CGImageSourceGetType(imageRef)!
        let dataWithExif: NSMutableData = NSMutableData(data: data as Data)
        let destinationn: CGImageDestination = CGImageDestinationCreateWithData(dataWithExif as CFMutableData, uti, 1, nil)!
        
        CGImageDestinationAddImageFromSource(destinationn, imageRef, 0, properties as CFDictionary)
        CGImageDestinationFinalize(destinationn)
        
        let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let savePath: String = paths[0].appending("/\(filename).jpg")
        
        let manager: FileManager = FileManager.default
        let result = manager.createFile(atPath: savePath, contents: dataWithExif as Data,  attributes: nil)
        if result {
            print("Image with Exif info converting to NSData: Done! Ready  to upload")
        }
    }
}

extension NSDictionary {
    var swiftDictionary: Dictionary<String, Any> {
        var swiftDictionary = Dictionary<String, Any>()
        
        for key: Any in self.allKeys {
            let stringKey = key as! String
            if let keyValue = self.value(forKey: stringKey){
                swiftDictionary[stringKey] = keyValue
            }
        }
        return swiftDictionary
    }
}
