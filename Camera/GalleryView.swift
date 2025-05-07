import SwiftUI
import Photos
import SwiftData

struct GalleryView: View {
    @State var photos: [UIImage]
    @Binding var photoAssets: [PHAsset]
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?
    @State private var currentPhotos: [UIImage] = []
    @State private var selectedIndex: Int = 0
    @State private var imageFileURLs: [URL] = []

    @Query var takenPhotos: [TakenPhoto] = []

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
            loadImagesFromTakenPhotos()
        }
    }

    
    private func loadImagesFromTakenPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        print("📂 Attempting to load photos from: \(documentsURL.path)")
        print(takenPhotos)
        for photo in takenPhotos {
            let fileURL = documentsURL.appendingPathComponent(photo.filename)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.photos.insert(image, at: 0)
                        }
                    } else {
                        print("Could not decode image data for \(photo.filename)")
                    }
                } catch {
                    print("Error loading image data for \(photo.filename): \(error.localizedDescription)")
                }
            } else {
                print("File not found: \(photo.filename) in Documents directory")
            }
        }
    }
}
