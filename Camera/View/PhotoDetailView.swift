//import SwiftUI
//import Photos
//import UserNotifications
//
//
//struct PhotoDetailView: View {
////    @Binding var photoAssets: [PHAsset]
//    @Binding var photos: [UIImage]
//    @Binding var selectedIndex: Int
//
//    @Environment(\.presentationMode) var presentationMode
//    @Environment(\.modelContext) var context
//    
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Top Info Bar
//            HStack {
//                Button(action: {
//                    presentationMode.wrappedValue.dismiss()
//                }) {
//                    Image(systemName: "chevron.left")
//                        .font(.system(size: 20, weight: .medium))
//                        .padding()
//                }
//                Spacer()
//                VStack(spacing: 2) {
////                    Text(getDayOfWeek(from: selectedIndex))
////                        .font(.headline)
////                    Text(getTimeString(from: selectedIndex))
////                        .font(.subheadline)
////                        .foregroundColor(.gray)
//                    Text("Photo Preview")
//                        .font(.headline)
//                }
//                Spacer()
//                Spacer().frame(width: 44) // Balance the left back button
//            }
//
//            // Main Image
//            GeometryReader { geo in
//                Image(uiImage: photos[selectedIndex])
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: geo.size.width, height: geo.size.height)
//            }
//
//            // Thumbnails Strip
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 8) {
//                    ForEach(photos.indices, id: \.self) { index in
//                        Image(uiImage: photos[index])
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: 60, height: 60)
//                            .clipShape(RoundedRectangle(cornerRadius: 6))
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 6)
//                                    .stroke(Color.blue, lineWidth: selectedIndex == index ? 2 : 0)
//                            )
//                            .onTapGesture {
//                                selectedIndex = index
//                            }
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .padding(.vertical, 5)
//            .background(Color(UIColor.systemBackground))
//
//            // Bottom Toolbar
//            HStack(spacing: 30) {
//                Spacer()
//                Button(action: { shareImage() }) {
//                    Image(systemName: "square.and.arrow.up")
//                }
//                Spacer()
////                Spacer()
////                Button(action: { saveImage() }) {
////                    Image(systemName: "arrow.down.to.line.alt") // Save icon
////                }
////                Spacer()
////                Spacer()
//                Button(action: { deleteImage() }) {
//                    Image(systemName: "trash")
//                }
//                Spacer()
//            }
//            .padding(.bottom, 20)
//            .padding(.top, 10)
//            .font(.title2)
//            .alert(isPresented: $showAlert) {
//                Alert(title: Text("Success"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
//            }
//        }
//        .navigationBarHidden(true)
//    }
//
//
//    private func shareImage() {
//        let image = photos[selectedIndex]
//        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let rootVC = windowScene.windows.first?.rootViewController {
//            rootVC.present(activityVC, animated: true, completion: nil)
//        }
//    }
//
//    private func deleteImage() {
//        // You can extend this to remove from storage too
//        photos.remove(at: selectedIndex)
//        photos.
////        photoAssets.remove(at: selectedIndex)
//        presentationMode.wrappedValue.dismiss()
//    }
//
//    private func saveImage() {
//        let image = photos[selectedIndex]
//        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
//            return
//        }
//
//        // Request access to Photos if needed
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                // Create a specific album if it doesn't exist
//                var album: PHAssetCollection?
//                let fetchOptions = PHFetchOptions()
//                fetchOptions.predicate = NSPredicate(format: "title == %@", "Apple Academy Challenge 2")
//                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
//                if let existingAlbum = collections.firstObject {
//                    album = existingAlbum
//                } else {
//                    // Create a new album
//                    PHPhotoLibrary.shared().performChanges({
//                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Apple Academy Challenge 2")
//                    }) { success, error in
//                        if success, let newAlbum = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions).firstObject {
//                            album = newAlbum
//                            saveImageToAlbum(album: album)
//                        }
//                    }
//                    return
//                }
//                saveImageToAlbum(album: album)
//            }
//        }
//    }
//
//    private func saveImageToAlbum(album: PHAssetCollection?) {
//        // Save the image to the specific album
//        PHPhotoLibrary.shared().performChanges({
//            if let album = album {
//                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photos[selectedIndex])
//                let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
//                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
//                albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
//            }
//        }) { success, error in
//            if success {
//                alertMessage = "Image saved to 'Apple Academy Challenge 2' album!"
//            } else {
//                alertMessage = "Failed to save image."
//            }
//            showAlert = true
//        }
//    }
//}

import SwiftUI
import Photos
import UserNotifications
import SwiftData

struct PhotoDetailView: View {
    @Binding var photos: [UIImage]
    @Binding var selectedIndex: Int

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext
    
    @Query var takenPhotos: [TakenPhoto] = []
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false

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
                    Text("Photo Preview")
                        .font(.headline)
                }
                Spacer()
                Spacer().frame(width: 44) // Balance the left back button
            }

            // Main Image
            GeometryReader { geo in
                if selectedIndex < photos.count {
                    Image(uiImage: photos[selectedIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }

            // Thumbnails Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                            .onTapGesture {
                                selectedIndex = index
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 5)
            .background(Color(UIColor.systemBackground))

            // Bottom Toolbar
            HStack(spacing: 30) {
                Spacer()
                Button(action: { shareImage() }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
                Spacer()
                Button(action: { saveImage() }) {
                    Image(systemName: "arrow.down.to.line.alt")
                        .foregroundColor(.blue)
                }
                Spacer()
                Button(action: { confirmDelete() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .padding(.bottom, 20)
            .padding(.top, 10)
            .font(.title2)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .confirmationDialog("Delete Photo", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteImage()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this photo? This action cannot be undone.")
            }
        }
        .navigationBarHidden(true)
    }

    private func shareImage() {
        if selectedIndex < photos.count {
            let image = photos[selectedIndex]
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
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

    private func saveImage() {
        guard selectedIndex < photos.count else { return }
        let image = photos[selectedIndex]
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Create a specific album if it doesn't exist
                let albumName = "Camera App Photos"
                var album: PHAssetCollection?
                
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
                
                if let existingAlbum = collections.firstObject {
                    album = existingAlbum
                    self.saveImageToPhotoLibrary(image: image, album: album)
                } else {
                    // Create new album
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    }) { success, error in
                        if success {
                            // Fetch the newly created album
                            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
                            album = collections.firstObject
                            self.saveImageToPhotoLibrary(image: image, album: album)
                        } else {
                            DispatchQueue.main.async {
                                self.alertMessage = "Failed to create album: \(error?.localizedDescription ?? "Unknown error")"
                                self.showAlert = true
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = "Photo library access denied. Please enable it in Settings."
                    self.showAlert = true
                }
            }
        }
    }

    private func saveImageToPhotoLibrary(image: UIImage, album: PHAssetCollection?) {
        PHPhotoLibrary.shared().performChanges({
            // Create asset request for the image
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            // Add to album if we have one
            if let album = album, let assetPlaceholder = assetRequest.placeholderForCreatedAsset {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
            }
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.alertMessage = "Photo saved to library successfully!"
                } else {
                    self.alertMessage = "Failed to save photo: \(error?.localizedDescription ?? "Unknown error")"
                }
                self.showAlert = true
            }
        }
    }
}
