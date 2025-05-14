import SwiftUI
import Photos
import UserNotifications
import SwiftData
import TipKit

struct PhotoDetailView: View {
    @Binding var photos: [UIImage]
    @Binding var selectedIndex: Int
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext
    
    @Query var takenPhotos: [TakenPhoto] = []
    
    @State private var saveTip = SaveTip()
    @State private var deleteTip = DeleteTip()
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false
    
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Info Bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .padding()
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(formatedDate(takenPhotos[selectedIndex].timestamp))
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(foramtedTime(takenPhotos[selectedIndex].timestamp))
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                Spacer()
                Spacer().frame(width: 44) // Balance the left back button
            }
            
            // Main Image
            //            TabView(selection: $selectedIndex) {
            //                ForEach(photos.indices, id: \.self) { index in
            //                    Image(uiImage: photos[index])
            //                        .resizable()
            //                        .scaledToFit()
            //                        .tag(index)
            //                        .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                }
            //            }
            //            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            TabView(selection: $selectedIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    ZoomView(image: photos[index])
                        .tag(index)
                }
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selectedIndex) { oldValue, newValue in
                    // Reset zoom when changing images
                    currentScale = 1.0
                    lastScale = 1.0
                }
            // Thumbnails Strip
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(photos.indices, id: \.self) { index in
                            Image(uiImage: photos[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue, lineWidth: selectedIndex == index ? 2 : 0)
                                )
                                .id(index) // penting agar bisa discroll ke sini
                                .onTapGesture {
                                    withAnimation {
                                        selectedIndex = index
                                        proxy.scrollTo(index, anchor: .center) // scroll otomatis
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            
            
            // Bottom Toolbar
            HStack {
                Button {
                    shareImage()
                }label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .popoverTip(saveTip)
                
                Spacer()
                
                Button {
                    confirmDelete()
                }label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                .popoverTip(deleteTip)
            }
            .padding()
            .font(.title2)
            .confirmationDialog("Delete Photo", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteImage()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this photo? This action cannot be undone.")
            }
        }
        .task{
            do{
                try Tips.configure([
                    .datastoreLocation(.applicationDefault),
                    .displayFrequency(.hourly),
                ])
            } catch {
                
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_us")
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo <= 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: date)
        }
    }
    
    private func foramtedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "HH.mm"
        return formatter.string(from: date)
    }
    
    //    private func shareImage() {
    //        if selectedIndex < photos.count {
    //            let image = photos[selectedIndex]
    //            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    //            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
    //               let rootVC = windowScene.windows.first?.rootViewController {
    //                rootVC.present(activityVC, animated: true, completion: nil)
    //            }
    //        }
    //    }
    
    //    private func shareImage() {
    //        if selectedIndex < photos.count {
    //            let image = photos[selectedIndex]
    //            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    //
    //            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
    //               let rootVC = windowScene.windows.first?.rootViewController {
    //
    //                activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
    //                    if completed {
    //                        // Simpan ke galeri
    //                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    //
    //                        // Tampilkan alert konfirmasi setelah share selesai
    //                        let alert = UIAlertController(title: "Saved", message: "Image has been saved to your photo library.", preferredStyle: .alert)
    //                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    //
    //                        // Penting: present alert di main queue
    //                        DispatchQueue.main.async {
    //                            rootVC.present(alert, animated: true, completion: nil)
    //                        }
    //                    }
    //                }
    //
    //                rootVC.present(activityVC, animated: true, completion: nil)
    //            }
    //        }
    //    }
    
    private func shareImage() {
        guard selectedIndex < photos.count else { return }
        let image = photos[selectedIndex]
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // For iPad support
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
                    saveImageToSnaptifyAlbum(image: image) {
                        // Delay alert slightly to wait for share sheet to dismiss cleanly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let alert = UIAlertController(
                                title: "Saved",
                                message: "Image has been saved to Snaptify album.",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            rootVC.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            
            // Delay slightly to prevent layout issues during modal presentation
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
    
    private func confirmDelete() {
        showDeleteConfirmation = true
    }
    
    private func deleteImage() {
        guard selectedIndex < photos.count else { return }
        
        // Get the filename of the image we're deleting
        let imageToDelete = photos[selectedIndex]
        
        // Find the corresponding TakenPhoto entry
        guard let correspondingPhotoEntry = findTakenPhotoForCurrentImage(at: selectedIndex) else {
            print("Error: Could not find corresponding TakenPhoto entry")
            return
        }
        
        // Delete the file from documents directory
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(correspondingPhotoEntry.filename)
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                print("Successfully deleted file: \(correspondingPhotoEntry.filename)")
            }
            
            // Delete from SwiftData
            modelContext.delete(correspondingPhotoEntry)
            
            // Update UI
            photos.remove(at: selectedIndex)
            
            // Adjust selectedIndex if necessary
            if selectedIndex >= photos.count && photos.count > 0 {
                selectedIndex = photos.count - 1
            } else if photos.isEmpty {
                // If no photos left, go back to gallery
                presentationMode.wrappedValue.dismiss()
            }
            
            alertMessage = "Photo successfully deleted"
            showAlert = true
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
            alertMessage = "Failed to delete photo: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func findTakenPhotoForCurrentImage(at index: Int) -> TakenPhoto? {
        // Since we don't have a direct link from image to takenPhoto record,
        // we need to find the corresponding TakenPhoto based on the order of loaded images
        // This assumes the photos array order corresponds to takenPhotos order
        
        if index < 0 || index >= photos.count || takenPhotos.isEmpty {
            return nil
        }
        
        // This logic assumes that GalleryView.loadImagesFromTakenPhotos() loaded images
        // in reverse order (newest first) of the takenPhotos array
        let reverseIndex = takenPhotos.count - 1 - index
        if reverseIndex >= 0 && reverseIndex < takenPhotos.count {
            return takenPhotos[reverseIndex]
        }
        
        return nil
    }
}
