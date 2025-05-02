import SwiftUI
import Photos

struct ContentView: View {
    @StateObject var cameraService = CameraService()
    @State private var lastPhoto: UIImage?
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()

            VStack {
                Spacer()
                
                // Photo preview or placeholder
                HStack {
                    if let image = lastPhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.leading)
                    } else {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.leading)
                    }

                    Spacer()

                    // Capture Button
                    Button(action: {
                        cameraService.capturePhoto { image in
                            if let img = image {
                                lastPhoto = img
                                savePhotoToAlbum(img)  // Save the image to a specific album
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.8), lineWidth: 2)
                            )
                    }

                    Spacer()

                    // Switch Camera Button
                    Button(action: {
                        cameraService.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding(.trailing)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            cameraService.configure()
        }
    }
    
    // Function to save the photo to a custom album
    func savePhotoToAlbum(_ image: UIImage) {
        let albumName = "Apple Academy Challenge 2"

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                var album: PHAssetCollection?
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
                
                collections.enumerateObjects { collection, _, _ in
                    if collection.localizedTitle == albumName {
                        album = collection
                    }
                }

                if album == nil {
                    // If album doesn't exist, create it
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    } completionHandler: { success, error in
                        if success {
                            self.saveImageToAlbum(image, albumName: albumName)
                        }
                    }
                } else {
                    self.saveImageToAlbum(image, albumName: albumName)
                }
            }
        }
    }

    // Function to save the image to the album
    func saveImageToAlbum(_ image: UIImage, albumName: String) {
        PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let placeholder = creationRequest.placeholderForCreatedAsset
            
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            var album: PHAssetCollection?
            collections.enumerateObjects { collection, _, _ in
                if collection.localizedTitle == albumName {
                    album = collection
                }
            }

            if let album = album {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([placeholder!] as NSArray)
            }
        } completionHandler: { success, error in
            if success {
                print("Photo saved to album: \(albumName)")
            } else if let error = error {
                print("Error saving photo to album: \(error.localizedDescription)")
            }
        }
    }
}
