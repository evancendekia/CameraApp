//
//  ZoomView.swift
//  Snaptify
//
//  Created by acqmal on 5/14/25.
//

import SwiftUI

struct ZoomView: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging when zoomed in
                            if scale > 1.0 {
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                
                                // Calculate bounds to prevent dragging outside image
                                let maxX = (geometry.size.width * (scale - 1)) / 2
                                let minX = -maxX
                                let maxY = (geometry.size.height * (scale - 1)) / 2
                                let minY = -maxY
                                
                                // Apply bounds with some elasticity
                                offset = CGSize(
                                    width: min(maxX, max(minX, newOffset.width)),
                                    height: min(maxY, max(minY, newOffset.height))
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            // Scale factor based on gesture with limits
                            let newScale = min(max(lastScale * value, 1.0), 4.0)
                            scale = newScale
                        }
                        .onEnded { value in
                            // If scale is less than minimum, animate back to 1.0
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
                .onTapGesture(count: 2) {
                    // Double-tap to reset or zoom
                    withAnimation {
                        if scale > 1.0 {
                            // Reset zoom
                            scale = 1.0
                            offset = .zero
                            lastScale = 1.0
                            lastOffset = .zero
                        } else {
                            // Zoom to 2x
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipped()
        }
    }
}
