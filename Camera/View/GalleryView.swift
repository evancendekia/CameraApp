import SwiftUI
import Photos
import SwiftData

struct PhotoItem: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let filename: String
}

struct GalleryView: View {
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
    @State private var selectedIndexes: Set<Int> = []
    @State private var isMultiSelectMode: Bool = false
    @State private var showMultiSelectDeleteConfirmation = false
    @State var photoItems: [PhotoItem] = []
    
    @Query var takenPhotos: [TakenPhoto] = []
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                if isMultiSelectMode {
                                    if selectedIndexes.contains(index) {
                                        selectedIndexes.remove(index)
                                    } else {
                                        selectedIndexes.insert(index)
                                    }
                                } else {
                                    selectedPhoto = photo
                                    if let index = photos.firstIndex(of: photo) {
                                        selectedIndex = index
                                    }
                                    isFullScreen = true
                                }
                                print("🥶 isMultiSelectMode: \(isMultiSelectMode)")
                                print("🥶 selectedIndexes: \(selectedIndexes)")
                            }
                            .overlay(
                                Group {
                                    if isMultiSelectMode && selectedIndexes.contains(index) {
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
            
            if isMultiSelectMode && !selectedIndexes.isEmpty {
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
                    
                    Text("\(selectedIndexes.count) Photo\(selectedIndexes.count > 1 ? "s" : "") Selected")
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
                        selectedIndexes.removeAll()
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
        let sortedIndexes = selectedIndexes.sorted(by: >)
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        for index in sortedIndexes {
            let photoItem = photoItems[index]
            let fileURL = documentsURL.appendingPathComponent(photoItem.filename)
            
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                    print("🗑️ Deleted file: \(photoItem.filename)")
                }
            } catch {
                print("❌ Could not delete file: \(error.localizedDescription)")
            }
            
            photoItems.remove(at: index)
        }
        
        selectedIndexes.removeAll()
        isMultiSelectMode = false
        photos = []
        loadImagesFromTakenPhotos()
    }
    
    private func shareImage() {
        // Only act if user selected multiple photos in multi-select mode
        guard isMultiSelectMode, !selectedIndexes.isEmpty else { return }
        
        let imagesToShare = selectedIndexes.compactMap { index in
            if index < photoItems.count {
                return photoItems[index].image
            }
            return nil
        }
        
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
        print(takenPhotos)
        for photo in takenPhotos {
//            print("ID: \(photo.id), timeStamp: \(photo.timestamp), filename: \(photo.filename), sessionID: \(photo.session)")
            let fileURL = documentsURL.appendingPathComponent(photo.filename)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.photos.insert(image, at: 0)
                            self.photoItems.insert(PhotoItem(image: image, filename: photo.filename), at: 0)
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
    }
}
