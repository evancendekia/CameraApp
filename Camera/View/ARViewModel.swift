import Foundation
import RealityKit
import ARKit
import SwiftUI
import AVFoundation

class ARViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    var arView: ARView?

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var frontCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?

    var photoCaptureCompletion: ((UIImage?) -> Void)?

    override init() {
        super.init()
        setupAVCapture()
    }
    func captureSnapshot(completion: @escaping (UIImage?) -> Void) {
         guard let arView = arView else {
             completion(nil)
             return
         }
        arView.snapshot(saveToHDR: false) { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }

     }
    // MARK: - AVCapture Setup
    private func setupAVCapture() {

        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }

        frontCamera = device
        do {
            frontCameraInput = try AVCaptureDeviceInput(device: frontCamera!)
            if captureSession!.canAddInput(frontCameraInput!) {
                captureSession!.addInput(frontCameraInput!)
            }
        } catch {
            print("Error configuring front camera: \(error)")
        }

        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession!.canAddOutput(photoOutput) {
            captureSession!.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
    }

    // MARK: - Public Capture Method
    func captureHighResolutionPhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletion = completion

        if photoOutput == nil || captureSession == nil {
            setupAVCapture()
        }

        guard let output = photoOutput else {
            completion(nil)
            return
        }

        // Pause ARKit
        arView?.session.pause()
        captureSession?.startRunning()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                let settings = AVCapturePhotoSettings()
                settings.isHighResolutionPhotoEnabled = true

                output.capturePhoto(with: settings, delegate: self)
                
                // Return to the main thread after the capture is initiated
                DispatchQueue.main.async {}
            }
    }

    // MARK: - AVCapture Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            captureSession?.stopRunning()
            restartSession()
        }

        if let error = error {
            DispatchQueue.main.async { self.photoCaptureCompletion?(nil) }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else {
            DispatchQueue.main.async { self.photoCaptureCompletion?(nil) }
            return
        }
        
        let fixedOrientationImage = image.fixedOrientation()
        let fixedImage = fixedOrientationImage.withHorizontallyFlippedOrientation()

        DispatchQueue.main.async { self.photoCaptureCompletion?(fixedImage) }
    }
    private func flipImageHorizontally(image: UIImage) -> UIImage? {
          UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
          guard let context = UIGraphicsGetCurrentContext(),
                let cgImage = image.cgImage else {
              return nil
          }

          // Flip horizontally: move origin to the right edge and flip the x-axis
          context.translateBy(x: image.size.width, y: 0)
          context.scaleBy(x: -1.0, y: 1.0)

          // Draw the original image into the context
          context.draw(cgImage, in: CGRect(origin: .zero, size: image.size))

          let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()

          return flippedImage
      }

    // MARK: - ARKit Session Restart
    func restartSession() {
        guard let arView = arView else { return }
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        config.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func pauseSession(){
        arView?.session.pause()
        captureSession?.stopRunning()
    }
}
extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return normalizedImage
    }
}
