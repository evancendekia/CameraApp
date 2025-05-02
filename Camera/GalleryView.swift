import SwiftUI

struct GalleryView: View {
    var photos: [UIImage]  // Pass the photos array from ContentView
    @Binding var isFullScreen: Bool
    @Binding var selectedPhoto: UIImage?

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
        }
        .navigationBarTitle("Gallery", displayMode: .inline)
        .onAppear {
            // Gallery view appeared, make sure full-screen mode is off.
            isFullScreen = false
        }
    }
}
