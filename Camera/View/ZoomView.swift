//
//  ZoomView.swift
//  Snaptify
//
//  Created by acqmal on 5/14/25.
//

import SwiftUI

struct ZoomView: View {
    let image: UIImage
    let currentIndex: Int
    @Binding var index: Int

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .tag(currentIndex)
                .scaleEffect(scale)
                .offset(offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = min(max(lastScale * value, 1.0), 4.0)
                            scale = newScale
                        }
                        .onEnded { _ in
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    offset = .zero
                                }
                            } else if scale > 4.0 {
                                scale = 4.0
                            }
                            lastScale = scale
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            guard scale > 1.0 else { return }
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            
                            let maxX = (geometry.size.width * (scale - 1)) / 2
                            let minX = -maxX
                            let maxY = (geometry.size.height * (scale - 1)) / 2
                            let minY = -maxY
                            
                            offset = CGSize(
                                width: min(maxX, max(minX, newOffset.width)),
                                height: min(maxY, max(minY, newOffset.height))
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                ).onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastScale = 1.0
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }.onChange(of: index) { _, _ in
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
        }
    }
}
