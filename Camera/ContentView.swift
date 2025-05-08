import SwiftUI
import Photos
import TipKit

struct ButtonTip : Tip {
    var title: Text{
        Text("Button Start")
    }
    
    var message: Text?{
        Text("Tap to start automatic photo capture hands free and hassle-free")
    }
    
    @Parameter
    static var isShown: Bool = false


    var rules: [Rule] {
        // Define a rule based on the app state.
        #Rule(Self.$isShown) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }

    var options: [TipOption] { [
        Tips.MaxDisplayCount(1),
        Tips.IgnoresDisplayFrequency(true),
    ] }
}

//struct GaleryPreviewTip: Tip {
//    var title: Text{
//        Text("Galery")
//    }
//    
//    var message: Text?{
//        Text("Gallery yang menyimpan foto foto hasil capture")
//    }
//    
//    var options: [TipOption] { [
//        Tips.MaxDisplayCount(1),
//        Tips.IgnoresDisplayFrequency(true),
//    ] }
//}

struct ResultPhotoTip: Tip {
    var title: Text{
        Text("Click here ")
    }
    
    var message: Text?{
        Text("to see your result Photo")
    }
    
    var options: [TipOption]{
        [
            Tips.MaxDisplayCount(1),
            Tips.IgnoresDisplayFrequency(true),
        ]
    }
}





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
    
    @State private var isExpressionDetectionEnabled: Bool = false
    @State private var firstTry: Bool = true
    
    @State private var isShown: Bool = false
    
    @State private var secondTry: Bool = false
    
    //MARK: TIP VAR
    @State var TipShown = TipGroup(.ordered){
//        GaleryPreviewTip()
        ButtonTip()
        ResultPhotoTip()
    }
    
    @State private var activeButtonId: String? = nil
    
    @State private var disabelButton = true
    
    @State private var hasHiddenSmileMessage = false
    @State private var isSmileTipVisible: Bool = false
    @State private var isResultPhotoTipVisible: Bool = false
    
    @State private var isAnimateButtonStart: Bool = false
    
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
                    if isExpressionDetectionEnabled && !hasHiddenSmileMessage && firstTry{
                        VStack {
                            Text("Smile to get capture")
                                .font(.title)
                            
                            Text("The app captures your smile and saves it!")
                                .font(.caption)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    hasHiddenSmileMessage = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        hasHiddenSmileMessage = false
                                    }
                                }
                            }
                            
                            
                            
                        }
                        .foregroundStyle(.black)
                        .frame(width: 328, height: 126)
                        .background(.ultraThickMaterial)
                        .cornerRadius(20)
                        .padding(.bottom, 50)
                        
                    }
                    
                    HStack {
                        Button {
                            showingGallery = true
//                            activeButtonId = "button1"
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
//                                    .popoverTip(TipShown.currentTip as? GaleryPreviewTip)
                                    .popoverTip(isResultPhotoTipVisible ? ResultPhotoTip() : nil)
                            }
                        }
                        .disabled(disabelButton)
                        
                        
                        //MARK: PHOTO GALERY TIP
                        
                        
                        
                        Spacer()
                        
                        //                        Toggle("Enable Expression Detection", isOn: $isExpressionDetectionEnabled)
                        //                            .padding()
                        //                            .foregroundColor(.white)
                        
                        
                        ZStack{
                            // MARK: ANIMASI BUTTON
                            RoundedRectangle(cornerRadius: 100)
                                .fill(isAnimateButtonStart ? Color.white : .clear)
                                .frame(width: 75, height: 75)
                                .blur(radius: isAnimateButtonStart ? 20 : 0)
                                .onAppear{
                                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)){
                                        ButtonTip.isShown.toggle()
                                        
                                        print(ButtonTip.isShown)
                                        
                                        isAnimateButtonStart = true
                                    }
                                }
                                
                            
                            Button(action: {
                                //MARK: DISABLE BUTTON
                                
                                disabelButton = false
                                isExpressionDetectionEnabled = !isExpressionDetectionEnabled
                                if isExpressionDetectionEnabled == false && firstTry {
                                    firstTry = false
                                }
                                
                                //                            if isExpressionDetectionEnabled {
                                //                                isSmileTipVisible = true
                                //                            }
                                
                                if !isExpressionDetectionEnabled {
                                    isResultPhotoTipVisible = true
                                }
                                
                                
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
                                .popoverTip(TipShown.currentTip as? ButtonTip)
                                
                                //                            .popoverTip(isSmileTipVisible ? TipShown.currentTip as? SmileTip: nil)
                            }
                            .disabled(activeButtonId != nil && activeButtonId != "button2")
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
            .task {
                do {
                    try Tips.resetDatastore()
                    try Tips.configure([
                        .datastoreLocation(.applicationDefault)
                    ])
                }
                catch {
                    print("Error initializing TipKit \(error.localizedDescription)")
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


#Preview {
    ContentView()
}
