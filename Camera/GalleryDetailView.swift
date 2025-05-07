import SwiftUI
import Photos

struct GalleryDetailView: View {
    @Binding var photoAssets: [PHAsset]
    @Binding var photos: [UIImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            // Large Image Preview
            TabView(selection: $selectedIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    Image(uiImage: photos[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Thumbnail Scroll View
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(photos.indices, id: \.self) { index in
                        Image(uiImage: photos[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedIndex = index
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            // Bottom Toolbar
            HStack {
                Button {
                    // action favorite
                    
                }label: {
                    Image(systemName: "heart")
                        .foregroundStyle(.blue)
                        .background(Color.gray.opacity(0.2))
                        .padding()
                }
                Spacer()
                Button {
                    // action delete
                    // Only attempt to delete if we have photos
//                    if !photoAssets.isEmpty && selectedIndex < photoAssets.count {
//                        let assetToDelete = photoAssets[selectedIndex]
//                        deletePhoto(asset: assetToDelete) { success in
//                            if success {
//                                // Update both arrays to keep them in sync
//                                photos.remove(at: selectedIndex)
//                                photoAssets.remove(at: selectedIndex)
//                                
//                                // Handle index after deletion
//                                if photoAssets.isEmpty {
//                                    // If no photos left, dismiss the view
//                                    dismiss()
//                                } else if selectedIndex >= photoAssets.count {
//                                    // If the deleted photo was the last one, adjust index
//                                    selectedIndex = max(0, photoAssets.count - 1)
//                                }
//                            }
//                        }
//                    }
                    
                }label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(Circle().fill(Color.gray.opacity(0.6)))
                }
                
            }
            .font(.system(size: 22))
            .padding()
            .padding(.bottom, 16)
            .foregroundColor(.white)
           
        }
        .ignoresSafeArea()
        .background(Color.white)
    }
    
    func toggleFavorite(asset: PHAsset, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Status favorit berhasil diubah.")
                    completion(true)
                } else {
                    print("Gagal mengubah status favorit: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }
    
    func deletePhoto(asset: PHAsset, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Foto berhasil dihapus.")
                    completion(true)
                } else {
                    print("Gagal menghapus foto: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }
    
    
    
}
