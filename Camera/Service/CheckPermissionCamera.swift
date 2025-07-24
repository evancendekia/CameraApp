//
//  CheckPermissionCamera.swift
//  Snaptify
//
//  Created by Gilang Ramadhan on 19/07/25.
//

import AVFoundation
import SwiftUI

enum CameraAuthorizationStatus {
    case authorized
    case denied
    case notDetermined
}

class CameraPermissionCheck: ObservableObject {
    @Published var cameraStatus: CameraAuthorizationStatus = .notDetermined
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraStatus = .authorized
        case .notDetermined:
            cameraStatus = .notDetermined
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraStatus = granted ? .authorized : .denied
                }
            }
        default:
            cameraStatus = .denied
        }
    }
}
