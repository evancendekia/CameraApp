//
//  CheckCamera.swift
//  Snaptify
//
//  Created by Gilang Ramadhan on 19/07/25.
//
import SwiftUI
import AVFoundation

struct ShowCamera: View {
    @StateObject private var cameraPermissionModel = CameraPermissionCheck()

    var body: some View {
        Group {
            switch cameraPermissionModel.cameraStatus {
            case .authorized:
                CameraView()
            case .denied:
                CameraPermissionView()
            case .notDetermined:
                Text("Checking camera permissions...")
            }
        }
        .onAppear {
            cameraPermissionModel.checkCameraPermission()
        }
    }
}
