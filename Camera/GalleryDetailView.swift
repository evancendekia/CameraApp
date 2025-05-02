import SwiftUI

struct GalleryDetailView: View {
    let photos: [UIImage]
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
                        .background(Color.black)
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
                .padding(.bottom, 8)
            }

            // Bottom Toolbar
            HStack {
                Spacer()
                Image(systemName: "square.and.arrow.up")
                Spacer()
                Image(systemName: "heart")
                Spacer()
                Image(systemName: "info.circle")
                Spacer()
                Image(systemName: "slider.horizontal.3")
                Spacer()
                Image(systemName: "trash")
                Spacer()
            }
            .font(.system(size: 22))
            .padding()
            .foregroundColor(.white)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea()
        .background(Color.black)
    }
}
