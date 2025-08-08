import SwiftUI
import Photos
import SwiftData

struct PhotoItem: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let filename: String
}

struct allSessionPhotos: Identifiable {
    var id: UUID
    let session: String
    let sessionNumber: Int
    let time: Date
    let sessionPhotos: [UIImage]
}

struct GalleryView: View {
    // MARK: - Properties
    @Environment(\.modelContext) var context
    
    // MARK: State
    @State var photos: [UIImage]
    @State private var currentPhotos: [UIImage] = []
    @State private var selectedIndex: Int = 0
    @State private var imageFileURLs: [URL] = []
    @AppStorage("IsWelcomeShow") var isWelcomeShow: Bool = false
    @State private var checkWelcome: Bool = false
    
    // MARK: Bindings
    @Binding var photoAssets: [PHAsset]
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?
    
    // MARK: Multi-select State
    @State private var selectedPhotoIDs: Set<UUID> = []
    @State private var isMultiSelectMode: Bool = false
    @State private var showMultiSelectDeleteConfirmation = false
    @State var photoItems: [PhotoItem] = []
    
    // MARK: Gesture State
    @State private var dragLocation: CGPoint? = nil
    @State private var alreadySelectedDuringDrag: Set<UUID> = []
    @State private var activeSessionDrag: String? = nil
    
    // MARK: Data
    @State var photosBySession: [allSessionPhotos] = []
    @Query(sort: [SortDescriptor(\Session.createdDate, order: .forward)]) var sessions: [Session]
    @Query(sort: [SortDescriptor(\TakenPhoto.timestamp, order: .reverse)]) var takenPhotos: [TakenPhoto]
    
    // MARK: - Computed Properties
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .current // Follows device time zone
        return formatter
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(Array(photosBySession.enumerated()), id: \.element.id) { _, item in
                    VStack(alignment: .leading){
                        Text(dateFormatter.string(from: item.time) + " Session \(item.sessionNumber)")
                            .fontWeight(.bold)
                            .padding(.leading, 25)
                        Text(countdownMessage(from: item.time))
                            .font(.footnote)
                            .padding(.leading, 25)
                            .padding(.bottom, -15)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(Array(item.sessionPhotos.enumerated()), id: \.offset) { _, photo in
                                GeometryReader { geo in
                                    let frame = geo.frame(in: .named("photoGrid"))
                                    
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .contentShape(Rectangle()) // seluruh area foto bisa ditap
                                        .highPriorityGesture(
                                            TapGesture().onEnded {
                                                if isMultiSelectMode {
                                                    toggleSelectionOnTap(photo: photo)
                                                } else {
                                                    selectedPhoto = photo
                                                    if let idx = photos.firstIndex(of: photo) { selectedIndex = idx }
                                                    isFullScreen = true
                                                }
                                            }
                                        )
                                        .overlay(
                                            Group {
                                                if isMultiSelectMode,
                                                   let matchingItem = photoItems.first(where: { $0.image == photo }),
                                                   selectedPhotoIDs.contains(matchingItem.id) {
                                                    ZStack {
                                                        Color.black.opacity(0.4)
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .resizable()
                                                            .frame(width: 16, height: 16)
                                                            .symbolRenderingMode(.palette)
                                                            .foregroundStyle(.white, .blue)
                                                            .background(Circle().stroke(Color.white, lineWidth: 3))
                                                            .padding(6)
                                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                                    }
                                                    .allowsHitTesting(false) // penting agar tap tetap kena foto
                                                }
                                            }
                                        )
                                        .onChange(of: dragLocation) { _, newPoint in
                                            if let newPoint = newPoint,
                                               frame.contains(newPoint),
                                               isMultiSelectMode,
                                               activeSessionDrag == item.session {
                                                if let matchingItem = photoItems.first(where: { $0.image == photo }) {
                                                    toggleSelectionDuringDrag(id: matchingItem.id)
                                                }
                                            }
                                        }
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        .coordinateSpace(name: "photoGrid")
                        .if(isMultiSelectMode) {
                            $0.simultaneousGesture(
                                DragGesture(minimumDistance: 10) // supaya tidak bentrok dengan tap
                                    .onChanged { value in
                                        let horizontalDistance = abs(value.translation.width)
                                        let verticalDistance = abs(value.translation.height)
                                        if horizontalDistance > verticalDistance {
                                            if activeSessionDrag == nil {
                                                activeSessionDrag = item.session
                                            }
                                            self.dragLocation = value.location
                                        }
                                    }
                                    .onEnded { _ in
                                        self.dragLocation = nil
                                        self.alreadySelectedDuringDrag.removeAll()
                                        self.activeSessionDrag = nil
                                    }
                            )
                        }
                        .padding()
                    }
                }
            }
            
            if isMultiSelectMode {
                let hasSelection = !selectedPhotoIDs.isEmpty
                
                HStack {
                    Button(action: { shareImage() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .disabled(!hasSelection)
                    .opacity(hasSelection ? 1 : 0.4)
                    .accessibilityHint("Bagikan foto yang dipilih")
                    
                    Spacer()
                    
                    Text("\(selectedPhotoIDs.count) Photo\(selectedPhotoIDs.count > 1 ? "s" : "") Selected")
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { showMultiSelectDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .disabled(!hasSelection)
                    .opacity(hasSelection ? 1 : 0.4)
                    .accessibilityHint("Hapus foto yang dipilih")
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: isMultiSelectMode)
                .animation(.easeInOut, value: selectedPhotoIDs) // update enable/disable dengan halus
            }
            
            
            Spacer()
                .navigationDestination(isPresented: $isFullScreen) {
                    PhotoDetailView(photos: $photos,selectedIndex: $selectedIndex)
                }
        }
        .alert(isPresented: $checkWelcome) {
            Alert(title: Text("Library Photo!"),
                  message: Text("Your photos will be stored in this library and will disappear in 24 hours."),
                  dismissButton: .default(Text("Done")))
        }
        .confirmationDialog(
            "Delete Photos",
            isPresented: $showMultiSelectDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedPhotos()
                showMultiSelectDeleteConfirmation = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These photos will be deleted permanently from Snaptify gallery. Are you sure?")
        }
        .navigationBarTitle("Gallery", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isMultiSelectMode ? "Done" : "Select") {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode { selectedPhotoIDs.removeAll() }
                }
            }
        }
        .onAppear {
            photosBySession = []
            photos = []
            loadImagesFromTakenPhotos()
            if !isWelcomeShow {
                checkWelcome = true
                isWelcomeShow = true
            }
        }
    }
    
    func countdownMessage(from date: Date) -> String {
        let now = Date()
        let triggerInterval: TimeInterval = 24 * 60 * 60
        let elapsed = now.timeIntervalSince(date)
        
        if elapsed <= triggerInterval {
            let remaining = triggerInterval - elapsed
            let hours = Int(remaining) / 3600
            return "Your Photos in this session will be deleted in \(hours)h"
        } else {
            return ""
        }
    }
    
    func deleteSelectedPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let itemsToDelete = photoItems.filter { selectedPhotoIDs.contains($0.id) }
        var sessionIDToDelete: String?
        
        for item in itemsToDelete {
            let fileURL = documentsURL.appendingPathComponent(item.filename)
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
            }
            
            if let takenPhoto = takenPhotos.first(where: { $0.filename == item.filename }) {
                sessionIDToDelete = takenPhoto.session
                context.delete(takenPhoto)
            }
            
            photoItems.removeAll { $0.id == item.id }
        }
        
        if let sessionID = sessionIDToDelete {
            let descriptor = FetchDescriptor<TakenPhoto>(predicate: #Predicate { $0.session == sessionID })
            let remainingPhotos = try! context.fetch(descriptor)
            if remainingPhotos.isEmpty {
                if let sessionToDelete = sessions.first(where: { $0.id == sessionID }) {
                    context.delete(sessionToDelete)
                }
            }
        }
        
        selectedPhotoIDs.removeAll()
        isMultiSelectMode = false
        photosBySession = []
        photos = []
        loadImagesFromTakenPhotos()
    }
    
    private func shareImage() {
        guard isMultiSelectMode, !selectedPhotoIDs.isEmpty else { return }
        let selectedItems = photoItems.filter { selectedPhotoIDs.contains($0.id) }
        let imagesToShare = selectedItems.map { $0.image }
        
        let activityVC = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private func loadImagesFromTakenPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var photosForSession : [UIImage] = []
        var sessionCountByDay: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for session in sessions {
            let sessionId = session.id
            photosForSession = []
            
            let descriptor = FetchDescriptor<TakenPhoto>(predicate: #Predicate { $0.session == sessionId })
            let photosOfSession: [TakenPhoto] = try! context.fetch(descriptor)
            if photosOfSession.isEmpty { continue }
            
            for photo in photosOfSession {
                let fileURL = documentsURL.appendingPathComponent(photo.filename)
                if fileManager.fileExists(atPath: fileURL.path) {
                    if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                        photosForSession.append(image)
                        DispatchQueue.main.async {
                            self.photoItems.insert(PhotoItem(image: image, filename: photo.filename), at: 0)
                            self.photos.insert(image, at: 0)
                        }
                    }
                }
            }
            
            let dateKey = dateFormatter.string(from: session.createdDate)
            sessionCountByDay[dateKey, default: 0] += 1
            let sessionNumber = sessionCountByDay[dateKey]!
            
            self.photosBySession.insert(
                allSessionPhotos(id: UUID(), session: sessionId, sessionNumber: sessionNumber, time: session.createdDate, sessionPhotos: photosForSession),
                at: 0
            )
        }
    }
    
    private func toggleSelectionDuringDrag(id: UUID) {
        if !alreadySelectedDuringDrag.contains(id) {
            if selectedPhotoIDs.contains(id) {
                selectedPhotoIDs.remove(id)
            } else {
                selectedPhotoIDs.insert(id)
            }
            alreadySelectedDuringDrag.insert(id)
        }
    }
    
    private func toggleSelectionOnTap(photo: UIImage) {
        guard let matchingItem = photoItems.first(where: { $0.image == photo }) else { return }
        if selectedPhotoIDs.contains(matchingItem.id) {
            selectedPhotoIDs.remove(matchingItem.id)
        } else {
            selectedPhotoIDs.insert(matchingItem.id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
