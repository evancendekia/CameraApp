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
    
    @Environment(\.modelContext) var context
    @State var photos: [UIImage]
    @Binding var photoAssets: [PHAsset]
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?
    @State private var currentPhotos: [UIImage] = []
    @State private var selectedIndex: Int = 0
    @State private var imageFileURLs: [URL] = []
    @AppStorage("IsWelcomeShow") var isWelcomeShow: Bool = false
    @State private var checkWelcome: Bool = false
    
    // MARK: state for multi-select image
    @State private var selectedPhotoIDs: Set<UUID> = []
    @State private var isMultiSelectMode: Bool = false
    @State private var showMultiSelectDeleteConfirmation = false
    @State var photoItems: [PhotoItem] = []
    
    @State var photosBySession: [allSessionPhotos] = []
    @Query(sort: [SortDescriptor(\Session.createdDate, order: .forward)]) var sessions: [Session]
    @Query(sort: [SortDescriptor(\TakenPhoto.timestamp, order: .reverse)]) var takenPhotos: [TakenPhoto]
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .current // Follows device time zone
        return formatter
    }
    func countdownMessage(from date: Date) -> String {
        let now = Date()
        let triggerInterval: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
        let elapsed = now.timeIntervalSince(date)
        

        if elapsed <= triggerInterval {
            let remaining = triggerInterval - elapsed
            let hours = Int(remaining) / 3600
//            let minutes = (Int(remaining) % 3600) / 60
            
            print("elapsed",elapsed)
            print(date)
            print("Your Photos in this session will be deleted in \(hours)h")
            
            return "Your Photos in this session will be deleted in \(hours)h"
        }else{
            return ""
        }
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(Array(photosBySession.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading){
                        Text(dateFormatter.string(from: item.time) + " Session \(item.sessionNumber)")
                            .fontWeight(.bold)
                            .padding(.leading, 25)
                        Text(countdownMessage(from: item.time))
                            .font(.footnote)
                            .padding(.leading, 25)
                            .padding(.bottom, -15)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            
                            ForEach(Array(item.sessionPhotos.enumerated()), id: \.offset) { index, photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onTapGesture {
                                        if isMultiSelectMode {
                                            if let matchingItem = photoItems.first(where: { $0.image == photo }) {
                                                let id = matchingItem.id
                                                if selectedPhotoIDs.contains(id) {
                                                    selectedPhotoIDs.remove(id)
                                                } else {
                                                    selectedPhotoIDs.insert(id)
                                                }
                                            }
                                        } else {
                                            selectedPhoto = photo
                                            if let index = photos.firstIndex(of: photo) {
                                                selectedIndex = index
                                            }
                                            isFullScreen = true
                                        }
                                        print("🥶 isMultiSelectMode: \(isMultiSelectMode)")
                                        print("🥶 selectedPhotoIDs: \(selectedPhotoIDs)")
                                        
                                    }
                                    .overlay(
                                        Group {
                                            if isMultiSelectMode, let matchingItem = photoItems.first(where: { $0.image == photo }),
                                               selectedPhotoIDs.contains(matchingItem.id)
 {
                                                Color.black.opacity(0.4)
                                                    .overlay(Image(systemName: "checkmark.circle.fill")
                                                        .resizable()
                                                        .foregroundColor(.white)
                                                        .frame(width: 24, height: 24)
                                                        .padding(6),
                                                             alignment: .topTrailing
                                                    )
                                                    .allowsHitTesting(false)
                                            }
                                        }
                                    )
                            }
                        }
                        .padding()
                    }
                    
                    
                }
            }
            
            if isMultiSelectMode && !selectedPhotoIDs.isEmpty {
                HStack {
                    Button(action: {
                        // logic for save selected photos
                        shareImage()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("\(selectedPhotoIDs.count) Photo\(selectedPhotoIDs.count > 1 ? "s" : "") Selected")
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        // logic for delete selected photos
                        showMultiSelectDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            
            Spacer()
                .navigationDestination(isPresented: $isFullScreen) {
                    PhotoDetailView(photos: $photos,selectedIndex: $selectedIndex)
                }
        }.alert(isPresented: $checkWelcome) {
            Alert(title: Text("Library Photo!"), message: Text("Your photos will be stored in this library and will disappear in 24 hours."), dismissButton: .default(Text("Done")))
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
                    if !isMultiSelectMode {
                        selectedPhotoIDs.removeAll()
                    }
                }
            }
        }
        .onAppear {
            photos = []
            loadImagesFromTakenPhotos()
            if !isWelcomeShow {
                checkWelcome = true
                isWelcomeShow = true
            }
        }
    }
    
    func deleteSelectedPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let itemsToDelete = photoItems.filter { selectedPhotoIDs.contains($0.id) }
        for item in itemsToDelete {
            let fileURL = documentsURL.appendingPathComponent(item.filename)
            
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                    print("🗑️ Deleted file: \(item.filename)")
                }
            } catch {
                print("❌ Could not delete file: \(error.localizedDescription)")
            }
            
            photoItems.removeAll { selectedPhotoIDs.contains($0.id) }
        }
        
        selectedPhotoIDs.removeAll()
        isMultiSelectMode = false
        photos = []
        loadImagesFromTakenPhotos()
    }
    
    private func shareImage() {
        // Only act if user selected multiple photos in multi-select mode
        guard isMultiSelectMode, !selectedPhotoIDs.isEmpty else { return }
        let selectedItems = photoItems.filter { selectedPhotoIDs.contains($0.id) }
        let imagesToShare = selectedItems.map { $0.image }
        
        let activityVC = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                if completed {
                    for img in imagesToShare {
                        saveImageToSnaptifyAlbum(image: img) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                let alert = UIAlertController(
                                    title: "Saved",
                                    message: "\(imagesToShare.count) photo\(imagesToShare.count > 1 ? "s" : "") saved to Snaptify album.",
                                    preferredStyle: .alert
                                )
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                rootVC.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                rootVC.present(activityVC, animated: true)
            }
        }
        
    }
    
    
    // MARK: - Helper untuk menyimpan ke album Snaptify
    private func saveImageToSnaptifyAlbum(image: UIImage, completion: @escaping () -> Void) {
        func getOrCreateAlbum(named name: String, completion: @escaping (PHAssetCollection?) -> Void) {
            // Cari album yang sudah ada
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            var existingAlbum: PHAssetCollection? = nil
            fetchResult.enumerateObjects { collection, _, stop in
                if collection.localizedTitle == name {
                    existingAlbum = collection
                    stop.pointee = true
                }
            }
            
            if let album = existingAlbum {
                completion(album)
                return
            }
            
            // Kalau belum ada, buat album baru
            var albumPlaceholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }) { success, error in
                if success, let placeholder = albumPlaceholder {
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                    completion(fetchResult.firstObject)
                } else {
                    print("Gagal membuat album: \(error?.localizedDescription ?? "unknown error")")
                    completion(nil)
                }
            }
        }
        
        // Simpan ke album
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else { return }
            
            getOrCreateAlbum(named: "Snaptify") { album in
                guard let album = album else { return }
                
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                       let assetPlaceholder = creationRequest.placeholderForCreatedAsset {
                        let fastEnumeration = NSArray(array: [assetPlaceholder])
                        albumChangeRequest.addAssets(fastEnumeration)
                    }
                }) { success, error in
                    if success {
                        completion()
                    } else {
                        print("Error saving to album: \(error?.localizedDescription ?? "unknown")")
                    }
                }
            }
        }
    }
    
    private func loadImagesFromTakenPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("📂 Attempting to load photos from: \(documentsURL.path)")
        
        
        var photosForSession : [UIImage] = []
        var sessionCountByDay: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for session in sessions {
            let sessionId = session.id
            photosForSession = []
            
            let descriptor = FetchDescriptor<TakenPhoto>(
                predicate: #Predicate { $0.session == sessionId }
            )
            let photosOfSession: [TakenPhoto] = try! context.fetch(descriptor)
            
            if photosOfSession.isEmpty {
                continue
            }
                
            for photo in photosOfSession {
    //            print("ID: \(photo.id), timeStamp: \(photo.timestamp), filename: \(photo.filename), sessionID: \(photo.session)")
                let fileURL = documentsURL.appendingPathComponent(photo.filename)
                
                if fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        if let image = UIImage(data: data) {
                            photosForSession.append(image)
                            DispatchQueue.main.async {
                                self.photoItems.insert(PhotoItem(image: image, filename: photo.filename), at: 0)
                                self.photos.insert(image, at: 0)
                            }
                        } else {
                            print("Could not decode image data for \(photo.filename)")
                        }
                    } catch {
                        print("Error loading image data for \(photo.filename): \(error.localizedDescription)")
                    }
                } else {
                    print("😭 File not found: \(photo.filename) in Documents directory")
                }
            }
            
            // Determine session number based on the date
            let dateKey = dateFormatter.string(from: session.createdDate)
            sessionCountByDay[dateKey, default: 0] += 1
            let sessionNumber = sessionCountByDay[dateKey]!
            
            print("photosForSession",photosForSession.count)
            self.photosBySession.insert(
                allSessionPhotos(
                    id: UUID(),
                    session: sessionId,
                    sessionNumber: sessionNumber,
                    time: session.createdDate,
                    sessionPhotos: photosForSession
                ),
                at: 0
            )
            print("PhotosBySession",photosBySession)
            
            
        }
    }
}
