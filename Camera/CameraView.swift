import SwiftUI
import Photos


struct CameraView: View {
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
    
    @State private var isExpressionDetectionEnabled: Bool = false
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
//                CameraPreview(session: cameraService.session)
//                    .ignoresSafeArea()
                Color.black.opacity(1)
                    .ignoresSafeArea()
                VStack{
                    Spacer()
                    ARViewContainer(faces: $faces, faceID : $faceID, viewModel: arViewModel,isExpressionDetectionEnabled: $isExpressionDetectionEnabled)
                        .aspectRatio(3/4, contentMode: .fit)
                        .clipped()
                        .edgesIgnoringSafeArea(.all)
                        .padding(.bottom, 120)
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }
                
                Color.black
                    .opacity(showFlash ? 1 : 0)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.2), value: showFlash)
                VStack {
                    Spacer()
                    Text("Faces: \(numberOfFaces)").foregroundStyle(Color.white).font(.title)
                    Text("Smiling: \(numberOfSmiling)").foregroundStyle(Color.white).font(.title)
//                    List(faces) { face in
//                        Text("Face ID: \(face.id) - Expression: \(face.expression)")
//                    }
//                    .frame(maxHeight: 200)
                    HStack {
                        Button {
                           showingGallery = true
                        } label: {
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
//                        Toggle("Enable Expression Detection", isOn: $isExpressionDetectionEnabled)
//                            .padding()
//                            .foregroundColor(.white)
                        
                        Button(action: {
                            isExpressionDetectionEnabled = !isExpressionDetectionEnabled
//                            arViewModel.captureSnapshot { image in
//                                
//                                showFlash = true
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                    showFlash = false
//                                }
//                                if let img = image {
//                                    let croppedImage = cropToAspectRatio(image: img, aspectRatio: CGSize(width: 3, height: 4))
//                                    lastPhoto = croppedImage
//                                    savePhotoToAppStorage(croppedImage)
//                                } else {
//                                    print("No image captured")
//                                }
//                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 70, height: 70)

                                if isExpressionDetectionEnabled {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                        .frame(width: 40, height: 40)
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 60, height: 60)
                                }
                            }
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
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $showingGallery) {
                GalleryView(
                    photos: photos,
                    photoAssets: $photoAssets,
                    isFullScreen: $isFullScreen,
                    selectedPhoto: $selectedPhoto
                )
            }
            .onAppear {
                arViewModel.restartSession()
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    let now = Date()
                    faces.removeAll { face in
                        now.timeIntervalSince(face.lastSeen) > 0.5
                    }
                }
            }
            .onChange(of: showingGallery) { newValue in
                if newValue == false {
//                    loadPhotos() 
                }
            }
            .onChange(of: faces) { newFaces in
                numberOfFaces = newFaces.count
                numberOfSmiling = newFaces.filter { $0.expression.lowercased().contains("smiling") }.count
                
                let now = Date()
//                if numberOfFaces > 1 && numberOfSmiling == 2 && now.timeIntervalSince(lastCaptureTime) > 1 {
                if numberOfFaces > 0 && numberOfSmiling > 0 && now.timeIntervalSince(lastCaptureTime) > 1 {
                    
                    lastCaptureTime = now
                    arViewModel.captureSnapshot { image in
                        
                        showFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showFlash = false
                        }
                        if let img = image {
                            let croppedImage = cropToAspectRatio(image: img, aspectRatio: CGSize(width: 3, height: 4))
                            lastPhoto = croppedImage
                            savePhotoToAppStorage(croppedImage)
                        } else {
                            print("No image captured")
                        }
                    }
                }
            }
        }
    }
    
    func savePhotoToAppStorage(_ image: UIImage) {
        let fileManager = FileManager.default
        guard let data = image.jpegData(compressionQuality: 0.95) else { return }

        let filename = UUID().uuidString + ".jpg"
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            print("✅ Saved to: \(fileURL.lastPathComponent)")
            DispatchQueue.main.async {
                self.photos.insert(image, at: 0)
            }
        } catch {
            print("❌ Error saving image: \(error.localizedDescription)")
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
