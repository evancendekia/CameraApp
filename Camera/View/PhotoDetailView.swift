import SwiftUI
import Photos
import UserNotifications

struct PhotoDetailView: View {
//    @Binding var photoAssets: [PHAsset]
    @Binding var photos: [UIImage]
    @Binding var selectedIndex: Int

    @Environment(\.presentationMode) var presentationMode

    @State private var showAlert = false
    @State private var alertMessage = ""

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
//                    Text(getDayOfWeek(from: selectedIndex))
//                        .font(.headline)
//                    Text(getTimeString(from: selectedIndex))
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
                    Text("Photo Preview")
                        .font(.headline)
                }
                Spacer()
                Spacer().frame(width: 44) // Balance the left back button
            }

            // Main Image
            GeometryReader { geo in
                Image(uiImage: photos[selectedIndex])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width, height: geo.size.height)
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
                }
                Spacer()
                Spacer()
                Button(action: { saveImage() }) {
                    Image(systemName: "arrow.down.to.line.alt") // Save icon
                }
                Spacer()
                Spacer()
                Button(action: { deleteImage() }) {
                    Image(systemName: "trash")
                }
                Spacer()
            }
            .padding(.bottom, 20)
            .padding(.top, 10)
            .font(.title2)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Success"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationBarHidden(true)
    }


    private func shareImage() {
        let image = photos[selectedIndex]
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }

    private func deleteImage() {
        // You can extend this to remove from storage too
        photos.remove(at: selectedIndex)
//        photoAssets.remove(at: selectedIndex)
        presentationMode.wrappedValue.dismiss()
    }

    private func saveImage() {
        let image = photos[selectedIndex]
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }

        // Request access to Photos if needed
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Create a specific album if it doesn't exist
                var album: PHAssetCollection?
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title == %@", "Apple Academy Challenge 2")
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
                if let existingAlbum = collections.firstObject {
                    album = existingAlbum
                } else {
                    // Create a new album
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Apple Academy Challenge 2")
                    }) { success, error in
                        if success, let newAlbum = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions).firstObject {
                            album = newAlbum
                            saveImageToAlbum(album: album)
                        }
                    }
                    return
                }
                saveImageToAlbum(album: album)
            }
        }
    }

    private func saveImageToAlbum(album: PHAssetCollection?) {
        // Save the image to the specific album
        PHPhotoLibrary.shared().performChanges({
            if let album = album {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photos[selectedIndex])
                let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
            }
        }) { success, error in
            if success {
                alertMessage = "Image saved to 'Apple Academy Challenge 2' album!"
            } else {
                alertMessage = "Failed to save image."
            }
            showAlert = true
        }
    }
}
