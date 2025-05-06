import SwiftUI
import Photos

struct GalleryView: View {
    @State var photos: [UIImage]  // Pass the photos array from ContentView
    @Binding var photoAssets: [PHAsset]
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack {
            Text("Gallery")
                .font(.largeTitle)
                .padding()

            // Gallery of Thumbnails
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
                                isFullScreen = true
                            }
                    }
                }
                .padding()
            }
            
            Spacer()
            NavigationLink(destination: GalleryDetailView(photoAssets: $photoAssets, photos: $photos, selectedIndex: $selectedIndex), isActive: $isFullScreen) {
                EmptyView()
            }

        }
        .navigationBarTitle("Gallery", displayMode: .inline)
        .onAppear {
            // Gallery view appeared, make sure full-screen mode is off.
            isFullScreen = false
        }
    }
}
