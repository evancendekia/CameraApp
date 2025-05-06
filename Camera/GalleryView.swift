import SwiftUI
import Photos

struct GalleryView: View {
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?
    @State private var currentPhotos: [UIImage] = []
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack {
            Text("Gallery")
                .font(.largeTitle)
                .padding()

            // Gallery of Thumbnails
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(currentPhotos, id: \.self) { photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                selectedPhoto = photo
                                if let index = currentPhotos.firstIndex(of: photo) {
                                    selectedIndex = index
                                }
                                isFullScreen = true
                            }
                    }
                }
                .padding()
            }

            Spacer()

            // Full screen detail view navigation
            NavigationLink(
                destination: GalleryDetailView(photos: currentPhotos, selectedIndex: $selectedIndex),
                isActive: $isFullScreen
            ) {
                EmptyView()
            }
        }
        .navigationBarTitle("Gallery", displayMode: .inline)
        .onAppear {
            isFullScreen = false
            loadPhotos()
        }
    }

    // Load latest photos from custom album
    private func loadPhotos() {
        let albumName = "Apple Academy Challenge 2"
        var loadedPhotos: [UIImage] = []

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
                collections.enumerateObjects { collection, _, _ in
                    if collection.localizedTitle == albumName {
                        let assets = PHAsset.fetchAssets(in: collection, options: nil)
                        let imageManager = PHImageManager.default()
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true

                        assets.enumerateObjects { asset, _, _ in
                            imageManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { image, _ in
                                if let image = image {
                                    loadedPhotos.append(image)
                                }
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.currentPhotos = loadedPhotos.reversed() // newest first
                }
            }
        }
    }
}
