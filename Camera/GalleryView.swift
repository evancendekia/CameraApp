import SwiftUI
import Photos

struct GalleryView: View {
    @State var photos: [UIImage]  // Pass the photos array from ContentView
    @Binding var photoAssets: [PHAsset]
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?
    @State private var currentPhotos: [UIImage] = []
    @State private var selectedIndex: Int = 0
    @State private var imageFileURLs: [URL] = []

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(photos, id: \.self) { photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                selectedPhoto = photo
                                if let index = photos.firstIndex(of: photo) {
                                    selectedIndex = index
                                }
                                isFullScreen = true
                            }
                    }
                }
                .padding()
            }
            
            Spacer()
            .navigationDestination(isPresented: $isFullScreen) {
                PhotoDetailView(photos: $photos,selectedIndex: $selectedIndex)
            }
        }
        .navigationBarTitle("Gallery", displayMode: .inline)
        .onAppear {
            if photos.isEmpty {
                loadPhotos() // Only load if not already loaded
            }
            isFullScreen = false
        }
    }

    private func loadPhotos() {
        loadPhotosFromInternalStorage() // Load images from internal storage
    }

    private func loadPhotosFromInternalStorage() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let urls = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "png" }
                .sorted { $0.lastPathComponent > $1.lastPathComponent } // Newest first

            self.imageFileURLs = urls
            loadImagesFromFileURLs(urls)
        } catch {
            print("Error loading images from internal storage: \(error.localizedDescription)")
        }
    }

    private func loadImagesFromFileURLs(_ urls: [URL]) {
        var loadedPhotos: [UIImage] = []
        
        for url in urls {
            if let image = UIImage(contentsOfFile: url.path) {
                loadedPhotos.append(image)
            }
        }

        DispatchQueue.main.async {
            self.photos.append(contentsOf: loadedPhotos.reversed())
        }
    }

//    private func loadPhotosFromPhotoLibrary() {
//        let albumName = "Apple Academy Challenge 2"
//        var loadedPhotos: [UIImage] = []
//
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
//                collections.enumerateObjects { collection, _, _ in
//                    if collection.localizedTitle == albumName {
//                        let assets = PHAsset.fetchAssets(in: collection, options: nil)
//                        let imageManager = PHImageManager.default()
//                        let options = PHImageRequestOptions()
//                        options.isSynchronous = true
//
//                        assets.enumerateObjects { asset, _, _ in
//                            imageManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { image, _ in
//                                if let image = image {
//                                    loadedPhotos.append(image)
//                                }
//                            }
//                        }
//                    }
//                }
//
//                DispatchQueue.main.async {
//                    self.photos.append(contentsOf: loadedPhotos.reversed()) // Newest first
//                }
//            }
//        }
//    }
}
