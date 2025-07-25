import SwiftUI
import Photos
import SwiftData


struct TutorialStep {
    let id: Int
    let stepText: String
    let text: String
    let focusFrame: CGRect
    let padding: CGFloat = 16
    let showAbove : Bool
}


struct SpotlightView: View {
    let step: TutorialStep
    
    var body: some View {
        GeometryReader { geometry in
            Color.black.opacity(0.8)
                .mask(
                    Rectangle()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: step.focusFrame.width + step.padding, height: step.focusFrame.height + step.padding)
                                .position(x: step.focusFrame.midX, y: step.focusFrame.midY)
                                .blendMode(.destinationOut)
                        )
                )
                .compositingGroup()
                .edgesIgnoringSafeArea(.all)
        }
    }
}


struct TutorialOverlay: View {
    @Binding var stepIndex: Int
    let steps: [TutorialStep]
    
    var body: some View {
        ZStack {
            if stepIndex < steps.count {
                let step = steps[stepIndex]
                SpotlightView(step: step)
                
//                GeometryReader { geometry in
//                    VStack {
//                        
//                    }
//                    .position(
//                        x: geometry.size.width / 2,
//                        y: step.showAbove ? max(step.focusFrame.minY - 270, 60) : min(step.focusFrame.maxY - 30, geometry.size.height)
//                    )
//                }
//                .animation(.easeInOut, value: stepIndex)
                
                
                GeometryReader { geometry in
                    VStack {
                        if step.showAbove {
                            Text(step.stepText)
                                .foregroundStyle(.white)
                            
                            Text(step.text)
                                .foregroundStyle(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        } else {
                            Text(step.text)
                                .foregroundStyle(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                            Text(step.stepText)
                                .foregroundStyle(.white)
                        }
                    }
                    .position(
                        x: geometry.size.width / 2,
                        y:  step.showAbove ? max(step.focusFrame.minY - 60, 60) : min(step.focusFrame.maxY + 50, geometry.size.height)
                    )
                }
                .animation(.easeInOut, value: stepIndex)
                .edgesIgnoringSafeArea(.all)
                
                
            }
        }
        .onTapGesture {
            if stepIndex == 0 {
                stepIndex += 1
            }
        }
    }
}


struct GeometryGetter: View {
    var index: Int
    @Binding var frames: [CGRect]
    @Binding var isReady: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    updateFrame(geometry: geometry)
                }
                .onChange(of: geometry.frame(in: .global)) { _ in
                    updateFrame(geometry: geometry)
                }
        }
    }
    
    private func updateFrame(geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        
        guard frame.width > 0 && frame.height > 0 else { return }
        
        DispatchQueue.main.async {
            while frames.count <= index {
                frames.append(.zero)
            }
            
            frames[index] = frame
            
            let validFrames = frames.filter { $0 != .zero }
            if validFrames.count >= 2 {
                isReady = true
            }
        }
    }
}





struct CameraView: View {
    @Query(sort: [SortDescriptor(\Session.createdDate, order: .reverse)]) var sessions: [Session]
    @Query(sort: [SortDescriptor(\TakenPhoto.timestamp, order: .reverse)]) var takenPhotos: [TakenPhoto]
    
    var latestPhoto: TakenPhoto? {
        takenPhotos.first
    }
    @State private var currentSessionId: String = UUID().uuidString
    @StateObject var cameraService = CameraService()
    @State private var lastPhoto: UIImage?
    @State private var showingGallery = false
    @State private var photos: [UIImage] = []
    @State private var isFullScreen: Bool = false
    @State private var selectedPhoto: UIImage?
    @State private var photoAssets: [PHAsset] = []
    
    
    @State private var timeRemaining = 3600
    //    @State private var timeRemaining = 10
    @State private var timer: Timer? = nil
    @State private var isRunning = false
    @State private var showAlert = false
    
    
    @State private var faces: [FaceData] = []
    @State private var faceID: UUID = UUID()
    @StateObject var arViewModel = ARViewModel()
    @State private var numberOfFaces: Int = 0
    @State private var numberOfSmiling: Int = 0
    @State private var lastCaptureTime: Date = .distantPast
    @State private var showFlash = false
    
    @State private var isExpressionDetectionEnabled: Bool = false
    @State private var photoCounter: Int = 0
    
    
    @State private var animatingThumbnail: UIImage? = nil
    @State private var thumbnailScale: CGFloat = 1.0
    @State private var thumbnailOffset: CGSize = .zero
    
    @Environment(\.modelContext) var context
    
    //MARK: NEW TOOLTIP
    @State private var elementFrames: [CGRect] = []
    @State private var showTutorial = true
    @State private var stepIndexTutorial = 0
    @State private var frameIsReady = false
    @State private var showTutorialOverlayButtonStop: Bool = true
    
    @AppStorage("firstTry") private var firstTry: Bool = false
//    @State private var firstTry: Bool = false
    @State var isStopButtonTapped: Bool = false
    @State private var isSmileTipVisible: Bool = false
    @State private var disableButton = true
    @State private var hasHiddenSmileMessage = false
    @State private var isAnimateButtonStart: Bool = false
    @State private var tipAfterButtonStopRecord: Bool = false
    @State private var showCapturedMessage = false
    
    @State var isTutorialOverlayButtonStop: Bool = false
    
    //    @AppStorage("isAnimateButtonStart") var isAnimateButtonStart: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                //                CameraPreview(session: cameraService.session)
                //                    .ignoresSafeArea()
                //                Color.black.opacity(1).ignoresSafeArea()
                
                Color.white
                    .opacity(showFlash ? 1 : 0)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.25), value: showFlash)
                
                GeometryReader { geometry in
                    
                    let arWidth = geometry.size.width
                    let arHeight = arWidth * 4 / 3 // Because aspectRatio is 3:4 (width:height)
                    let arFrame = CGSize(width: arWidth, height: arHeight)
                    
                    ZStack{
                        
                        ARViewContainer(faces: $faces, faceID : $faceID, viewModel: arViewModel,isExpressionDetectionEnabled: $isExpressionDetectionEnabled)
                            .aspectRatio(3/4, contentMode: .fit)
                        //                        .aspectRatio(3/4, contentMode: .fill)
                            .clipped()
                            .ignoresSafeArea()
                            .padding(.bottom, 230)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 5/8)
                        // --- Animating thumbnail overlay ---
                        if let animatingThumbnail = animatingThumbnail {
                            Image(uiImage: animatingThumbnail)
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fill)
                                .frame(width: arFrame.width, height: arFrame.height)
                                .clipped()
                                .border(Color.white, width: 4)
                                .scaleEffect(thumbnailScale)
                                .offset(thumbnailOffset)
                                .zIndex(2)
                                .animation(.easeInOut(duration: 0.5), value: thumbnailScale)
                        }
                    }
                }
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 32))
                        .padding(5)
                        .overlay(
                            GeometryGetter(index: 0, frames: $elementFrames, isReady: $frameIsReady)
                                .allowsHitTesting(false)
                        )
                        .background(isExpressionDetectionEnabled ? Color(.red) : .clear, in: RoundedRectangle(cornerRadius: 5))
                        .foregroundStyle(.white)
                        
                        .frame(maxWidth: .infinity, alignment: .center)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.15)
                }
                .ignoresSafeArea()
                .zIndex(1)
                
                Color.black
                    .opacity(showFlash ? 1 : 0)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.2), value: showFlash)
                VStack {
                    Spacer()
                    //                                        Text("Faces: \(numberOfFaces)").foregroundStyle(Color.white).font(.title)
                    //                                        Text("Smiling: \(numberOfSmiling)").foregroundStyle(Color.white).font(.title)
                    //                    List(faces) { face in
                    //                        Text("Face ID: \(face.id) - Expression: \(face.expression)")
                    //                    }
                    //                    .frame(maxHeight: 200)
                    if isExpressionDetectionEnabled && !hasHiddenSmileMessage && !firstTry{
                        VStack {
                            Text(showCapturedMessage ? "Your smile is captured" : "Smile to get capture" )
                                .font(.largeTitle.bold())
                            
                            Text(!showCapturedMessage ? "The app captures your smile and saves it!" : "")
                                .font(.system(size: 15))
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    if showCapturedMessage {
                                        hasHiddenSmileMessage = false
                                    } else {
                                        hasHiddenSmileMessage = true
                                    }
                                    
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
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(20)
                        .padding(.bottom, 50)
                        
                    }
                    
                    
                    HStack {
                        if isExpressionDetectionEnabled == false {
                            Button {
                                showingGallery = true
                                stepIndexTutorial += 1
                                
                                if !firstTry {
                                    firstTry = true
                                }
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
                            .overlay(GeometryGetter(index: 3, frames: $elementFrames, isReady: $frameIsReady)) // result foto
                        }else{
                            VStack(){
                                Text("\(photoCounter)")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 30, weight: .bold, design: .default))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .frame(width: 60, height: 60)
                                    .padding(.horizontal, 10)
                                //                                .alignment(.center)
                                //                                    .background(
                                //                                        Rectangle()
                                //                                            .fill(Color.gray)
                                //                                            .frame(width: 60, height: 60)
                                //                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                //                                            .padding(.leading)
                                //                                    )
                            }
                            
                        }
                        
                        Spacer()
                        ZStack{
                            //                            RoundedRectangle(cornerRadius: 100)
                            //                                .fill(isAnimateButtonStart ? Color.white: .clear)
                            //                                .frame(width: 85, height: 85)
                            //                                .blur(radius: isAnimateButtonStart ? 20 : 0)
                            //                                .onAppear {
                            //                                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)){
                            //                                        isAnimateButtonStart = true
                            //                                    }
                            //                                }
                            Button(action: {
                                actionButton()
                                stepIndexTutorial += 1
                                print("firstry : \(firstTry)")
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                        .overlay( isTutorialOverlayButtonStop ?
                                                  GeometryGetter(index: 2, frames: $elementFrames, isReady: $frameIsReady) : nil
                                        )
                                        
                                    
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
                            .overlay{GeometryGetter(index: 1, frames: $elementFrames, isReady: $frameIsReady)}
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .padding(.bottom, 50)
                }
                
                ZStack{
                    if showTutorial && frameIsReady && elementFrames.count == 4 && !firstTry{
                        let tutorialSteps = createTutorialSteps()
                        
                        TutorialOverlay(
                                    stepIndex: $stepIndexTutorial,
                                    steps: tutorialSteps
                                )
                        .allowsHitTesting(stepIndexTutorial == 1 || stepIndexTutorial == 2 || stepIndexTutorial == 3 ? false : true)
                        .onChange(of: stepIndexTutorial) { newValue in
                            if newValue >= 4 {
                                showTutorial = false
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Finish capture your moment"),
                    message: Text("You got total \(photoCounter) pictures. \n Don’t forget to see the result and pick your best moment"),
                    dismissButton: .default(Text("OK"), action: {
                        resetTimer()
                        isSmileTipVisible = true
                    })
                )
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
                //                print("sessions",sessions)
                //                for session in sessions {
                //                    print("ID: \(session.id), Start: \(session.createdDate), End: \(session.finishedDate ?? Date())")
                //                }
                
                print("firts try: \(firstTry)")
//                UserDefaults.standard.removeObject(forKey: "firstTry")
                
                loadLatestTakenPhotos()
                
                arViewModel.restartSession()
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    let now = Date()
                    faces.removeAll { face in
                        now.timeIntervalSince(face.lastSeen) > 0.5
                    }
                }
            }
            .onChange(of: showingGallery) { newValue in
                if newValue == true {
                    arViewModel.pauseSession()
                }else{
                    arViewModel.restartSession()
                }
            }
            .onChange(of: faces) { newFaces in
                numberOfFaces = newFaces.count
                numberOfSmiling = newFaces.filter { $0.expression.lowercased().contains("smiling") }.count
                
                let now = Date()
                //                if numberOfFaces > 1 && numberOfSmiling == 2 && now.timeIntervalSince(lastCaptureTime) > 1 {
                if numberOfFaces > 0 && numberOfSmiling > 0 && now.timeIntervalSince(lastCaptureTime) > 10 {
                    
                    //capture
                    lastCaptureTime = now
                    arViewModel.captureSnapshot { image in
                        if let img = image {
                            //                            thumbnailScale = 1.0
                            //                            thumbnailOffset = .zero
                            animatingThumbnail = img
                            lastPhoto = img // Set early preview image
                            // But do not animate yet — wait for high-res to finish
                        }
                    }
                    
                    arViewModel.captureHighResolutionPhoto{ image in
                        
                        
                        showFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showFlash = false
                        }
                        if let img = image {
                            
                            lastPhoto = img
                            savePhotoToAppStorage(img)
                            photoCounter += 1
                            showCapturedMessage = true
                            withAnimation(.easeInOut(duration: 0.5)) {
                                thumbnailScale = 0.2
                                thumbnailOffset = CGSize(width: -150, height: 300)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                animatingThumbnail = nil
                                thumbnailScale = 1.0
                                thumbnailOffset = .zero
                            }
                        } else {
                            print("No image captured")
                            // Still remove the animating thumbnail if high-res failed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                animatingThumbnail = nil
                                thumbnailScale = 1.0
                                thumbnailOffset = .zero
                            }
                        }
                    }
                    
                    isTutorialOverlayButtonStop = true
                    
                    //selesai capture pertama kali
                    // stop
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showTutorialOverlayButtonStop = false
                    }
                    
                }
            }
        }
    }
    private func actionButton(){
        withAnimation(){
            isAnimateButtonStart = false
        }
        
        //        if !isExpressionDetectionEnabled {
        //            isSmileTipVisible = true
        //        }
        
        isExpressionDetectionEnabled = !isExpressionDetectionEnabled
        
        
        
        if isExpressionDetectionEnabled {
            //save session
            currentSessionId = UUID().uuidString
            let theSession = Session(id: currentSessionId, createdDate: Date())
            context.insert(theSession)
            try! context.save()
            
            
            
            UIApplication.shared.isIdleTimerDisabled = true
            photoCounter = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    UIApplication.shared.isIdleTimerDisabled = false
                    stopTimer()
                    showAlert = true
                }
            }
        }else{
            
            let descriptor = FetchDescriptor<Session>(
                predicate: #Predicate { $0.id == currentSessionId }
            )
            if let sessionToUpdate = try? context.fetch(descriptor).first {
                sessionToUpdate.finishedDate = Date()
                try? context.save()
                //               print("Session with id \(currentSessionId) updated.")
            } else {
                //               print("Session with id \(currentSessionId) not found.")
            }
            
            //            for session in sessions {
            //                print("ID: \(session.id), Start: \(session.createdDate), End: \(session.finishedDate ?? Date())")
            //            }
            
            UIApplication.shared.isIdleTimerDisabled = false
            stopTimer()
            showAlert = true
        }
    }
    
    private func createTutorialSteps() -> [TutorialStep] {
        var steps: [TutorialStep] = [
            TutorialStep(id: 0, stepText: "Tap anywhere to continue", text: "Auto Capture is only available for 1 hour!", focusFrame: elementFrames[0], showAbove: false),
            TutorialStep(id: 1, stepText: "Tap the start button to continue", text: "Tap to start automatic photo capture hands free and hassle-free.", focusFrame: elementFrames[1], showAbove: true)
        ]
        
        // Hanya tambahkan step ini jika showCapturedMessage = true
        if isTutorialOverlayButtonStop && elementFrames.count > 2 {
            steps.append(TutorialStep(id: 2, stepText: "Tap the stop button to continue", text: "Click here to stop automatic photo capture.", focusFrame: elementFrames[2], showAbove: true))
        }
        
        // Step untuk gallery
        if elementFrames.count > 3 && isTutorialOverlayButtonStop{
            steps.append(TutorialStep(id: 3, stepText: "Tap the gallery button to continue", text: "Click here to see your result Photos.", focusFrame: elementFrames[3], showAbove: true))
        }
        
        return steps
    }
    
    private func loadLatestTakenPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        print("📂 Attempting to load photos from: \(documentsURL.path)")
        if let photo = latestPhoto {
            let fileURL = documentsURL.appendingPathComponent(photo.filename)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let image = UIImage(data: data) {
                        
                        //                        print("lastPhoto",lastPhoto)
                        DispatchQueue.main.async {
                            self.lastPhoto = image
                        }
                    }
                } catch {
                    print("Error loading image data for \(photo.filename): \(error.localizedDescription)")
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
            let thePhoto = TakenPhoto(id: UUID(), timestamp: Date(), filename: filename, session: currentSessionId)
            context.insert(thePhoto)
            try! context.save()
            
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
    func timeString(from seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    func stopTimer() {
        isExpressionDetectionEnabled = false
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func resetTimer() {
        timeRemaining = 3600
    }
}



struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}


#Preview {
    CameraView()
}
