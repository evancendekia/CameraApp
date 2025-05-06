import SwiftUI
import Photos

struct PhotoDetailView: View {
    @Binding var photoAssets: [PHAsset]
    @Binding var photos: [UIImage]
    @Binding var selectedIndex: Int

    @Environment(\.presentationMode) var presentationMode

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
                    Text(getDayOfWeek(from: selectedIndex))
                        .font(.headline)
                    Text(getTimeString(from: selectedIndex))
                        .font(.subheadline)
                        .foregroundColor(.gray)
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
                Button(action: { shareImage() }) {
                    Image(systemName: "square.and.arrow.up")
                }
                Button(action: { /* favorite action */ }) {
                    Image(systemName: "heart")
                }
                Button(action: { /* info action */ }) {
                    Image(systemName: "info.circle")
                }
                Button(action: { /* edit action */ }) {
                    Image(systemName: "slider.horizontal.3")
                }
                Button(action: { deleteImage() }) {
                    Image(systemName: "trash")
                }
            }
            .padding(.bottom, 20)
            .padding(.top, 10)
            .font(.title2)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Helper Methods

    private func getDayOfWeek(from index: Int) -> String {
        if index < photoAssets.count {
            let asset = photoAssets[index]
            if let creationDate = asset.creationDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: creationDate)
            }
        }
        return "Unknown Day"
    }

    private func getTimeString(from index: Int) -> String {
        if index < photoAssets.count {
            let asset = photoAssets[index]
            if let creationDate = asset.creationDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.string(from: creationDate)
            }
        }
        return "Unknown Time"
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
        photoAssets.remove(at: selectedIndex)
        presentationMode.wrappedValue.dismiss()
    }
}
