//
//  ContentView.swift
//  Camera
//
//  Created by M. Evan Cendekia Suryandaru on 02/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var cameraService = CameraService()
    @State private var lastPhoto: UIImage?

    var body: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()

            VStack {
                Spacer()
                
                HStack {
                    if let image = lastPhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.leading)
                    } else {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.leading)
                    }

                    Spacer()
                    
                    Button(action: {
                        cameraService.capturePhoto { image in
                            if let img = image {
                                lastPhoto = img
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.8), lineWidth: 2)
                            )
                    }

                    Spacer()

                    Button(action: {
                        cameraService.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding(.trailing)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            cameraService.configure()
        }
    }
}

//#Preview {
//    ContentView()
//}
