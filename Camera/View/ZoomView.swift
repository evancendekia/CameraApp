//
//  ZoomView.swift
//  Snaptify
//
//  Created by acqmal on 5/14/25.
//

import SwiftUI

struct ZoomView: View {
    let image: UIImage
        let index: Int  // Regular property for the index
        
        @State private var scale: CGFloat = 1.0
        @State private var lastScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        
        // Flag to track if we're currently zoomed in
        @GestureState private var isInteracting: Bool = false
        
        var body: some View {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .tag(index)
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        // Simultaneous gesture recognizers
                        SimultaneousGesture(
                            DragGesture()
                                .updating($isInteracting) { _, state, _ in
                                    state = true
                                }
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
                                },
                            MagnificationGesture()
                                .updating($isInteracting) { _, state, _ in
                                    state = true
                                }
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
                    .allowsHitTesting(true)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .clipped()
                    // This is the key to fix swiping - disable TabView swipe when zoomed
                    .allowsHitTesting(isInteracting || scale > 1.0)
            }
            // Add this to reset view when switching between photos
            .onChange(of: index) { oldValue, newValue in
                if oldValue != newValue {
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                        lastScale = 1.0
                        lastOffset = .zero
                    }
                }
            }
        }
}
