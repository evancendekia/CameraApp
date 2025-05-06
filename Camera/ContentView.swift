import SwiftUI
import Photos

struct FaceData: Identifiable, Equatable {
    let id: UUID
    var expression: String
    var lastSeen: Date
}

struct ContentView: View {
    @StateObject var cameraService = CameraService()
    @State private var lastPhoto: UIImage?
    @State private var showingGallery = false
    @State private var photos: [UIImage] = []
    @State private var isFullScreen: Bool = false
    @State private var selectedPhoto: UIImage?
    @State private var photoAssets: [PHAsset] = []
    
    @State private var faces: [FaceData] = []
    @State private var faceID: UUID = UUID()
    @StateObject var arViewModel = ARViewModel()
    @State private var numberOfFaces: Int = 0
    @State private var numberOfSmiling: Int = 0
    @State private var lastCaptureTime: Date = .distantPast
    @State private var showFlash = false
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
//                CameraPreview(session: cameraService.session)
//                    .ignoresSafeArea()
                
                ARViewContainer(faces: $faces, faceID : $faceID, viewModel: arViewModel)
                    .aspectRatio(3/4, contentMode: .fit)
                    .clipped()
                    .edgesIgnoringSafeArea(.all)
                
                Color.black
                    .opacity(showFlash ? 1 : 0)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.2), value: showFlash)
                VStack {
                    Spacer()
//                    Text("Faces: \(numberOfFaces)").foregroundStyle(Color.white).font(.title)
//                    Text("Smiling: \(numberOfSmiling)").foregroundStyle(Color.white).font(.title)
//                    List(faces) { face in
//                        Text("Face ID: \(face.id) - Expression: \(face.expression)")
//                    }
//                    .frame(maxHeight: 200)
                    // Photo preview or placeholder
                    HStack {
                        NavigationLink(destination: GalleryView(photos: photos, photoAssets: $photoAssets, isFullScreen: $isFullScreen, selectedPhoto: $selectedPhoto)) {
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
                        }

                        Spacer()
                        
                        // Capture Button
                        Button(action: {
//                            arViewModel.captureSnapshot()
                            arViewModel.captureSnapshot { image in
                                
                                showFlash = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showFlash = false
                                }
                                if let img = image {
                                    let croppedImage = cropToAspectRatio(image: img, aspectRatio: CGSize(width: 3, height: 4))
                                    lastPhoto = croppedImage
                                    print("Got image from ARView snapshot")
//                                    lastPhoto = img
                                    savePhotoToAlbum(img)
                                } else {
                                    print("No image captured")
                                }
                            }
//                            cameraService.capturePhoto { image in
//                                if let img = image {
//                                    lastPhoto = img
//                                    savePhotoToAlbum(img)  // Save the image to a specific album with metadata
//                                }
//                            }
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
//                cameraService.configure()
                loadPhotos()
                arViewModel.restartSession()
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    let now = Date()
                    faces.removeAll { face in
                        now.timeIntervalSince(face.lastSeen) > 0.5
                    }
                }
            }
            .onChange(of: faces) { newFaces in
                numberOfFaces = newFaces.count
                numberOfSmiling = newFaces.filter { $0.expression.lowercased().contains("smiling") }.count
                
                let now = Date()
                if numberOfFaces > 1 && numberOfSmiling == 2 && now.timeIntervalSince(lastCaptureTime) > 1 {
                    
                    lastCaptureTime = now
                    arViewModel.captureSnapshot { image in
                        
                        showFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showFlash = false
                        }
                        if let img = image {
                            print("Got image from ARView snapshot")
                            lastPhoto = img
                            savePhotoToAlbum(img)
                        } else {
                            print("No image captured")
                        }
                    }
                }
            }
        }
    }
    
    // Function to save the photo to a custom album with metadata
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

    // Function to save the image to the album with custom metadata
    func saveImageToAlbum(_ image: UIImage, albumName: String) {
        // Request photo library access
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Check if the album already exists
                var album: PHAssetCollection?
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
                
                collections.enumerateObjects { collection, _, _ in
                    if collection.localizedTitle == albumName {
                        album = collection
                    }
                }

                // If album doesn't exist, create it
                if album == nil {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    }) { success, error in
                        if success {
                            self.saveImageToAlbum(image, albumName: albumName) // Try saving again
                        } else if let error = error {
                            print("Error creating album: \(error.localizedDescription)")
                        }
                    }
                    return
                }

                // Proceed to save image with metadata
                guard let imageData = image.jpegData(compressionQuality: 1.0),
                      let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                      let type = CGImageSourceGetType(imageSource) else {
                    print("Failed to prepare image source/type.")
                    return
                }

                // Add custom metadata (you can expand this as needed)
                let metadata: [String: Any] = [
                    kCGImagePropertyExifDictionary as String: [
                        kCGImagePropertyExifUserComment as String: "Taken with Apple Academy Challenge 2 App"
                    ]
                ]

                // Copy metadata
                let mutableMetadata = metadata as NSDictionary

                // Create mutable CFData from Data
                let mutableData = NSMutableData(data: imageData)
                guard let imageDestination = CGImageDestinationCreateWithData(mutableData as CFMutableData, type, 1, nil) else {
                    print("Failed to create image destination.")
                    return
                }

                CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, mutableMetadata)

                if CGImageDestinationFinalize(imageDestination),
                   let finalImage = UIImage(data: mutableData as Data) {

                    // Save the image with metadata to the custom album
                    PHPhotoLibrary.shared().performChanges {
                        let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: finalImage)
                        if let assetPlaceholder = creationRequest.placeholderForCreatedAsset {
                            let fetchOptions = PHFetchOptions()
                            fetchOptions.predicate = NSPredicate(format: "localizedTitle = %@", albumName)
                            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
                            if let album = collection {
                                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                                albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
                            }
                        }
                    } completionHandler: { success, error in
                        if success {
                            print("Photo saved to album '\(albumName)' successfully.")
                        } else {
                            print("Error saving photo: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                } else {
                    print("Failed to finalize image with metadata.")
                }
            } else {
                print("Photo library access denied.")
            }
        }
    }

    
    // Function to get image metadata (can be extended to include more metadata)
    func getImageMetadata() -> NSDictionary {
        let metadata: [String: Any] = [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifUserComment as String: "Taken with Apple Academy Challenge 2 App"
            ]
        ]
        return metadata as NSDictionary
    }

    // Function to load photos from the album
    func loadPhotos() {
        let albumName = "Apple Academy Challenge 2"
        var photoArray: [UIImage] = []
        var assetArray: [PHAsset] = []

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
                
                collections.enumerateObjects { collection, _, _ in
                    if collection.localizedTitle == albumName {
                        let assets = PHAsset.fetchAssets(in: collection, options: nil)
                        
                        assets.enumerateObjects { asset, _, _ in
                            let imageManager = PHImageManager.default()
                            let options = PHImageRequestOptions()
                            options.isSynchronous = true
                            
                            imageManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { image, _ in
                                if let image = image {
                                    photoArray.append(image)
                                    assetArray.append(asset)
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.photos = photoArray
                    self.photoAssets = assetArray
                }
            }
        }
    }
    func cropToAspectRatio(image: UIImage, aspectRatio: CGSize) -> UIImage {
        let originalSize = image.size
        let originalRatio = originalSize.width / originalSize.height
        let targetRatio = aspectRatio.width / aspectRatio.height
        
        var cropRect = CGRect.zero
        
        if originalRatio > targetRatio {
            // Too wide, crop sides
            let newWidth = originalSize.height * targetRatio
            let x = (originalSize.width - newWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: originalSize.height)
        } else {
            // Too tall, crop top and bottom
            let newHeight = originalSize.width / targetRatio
            let y = (originalSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: originalSize.width, height: newHeight)
        }
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
