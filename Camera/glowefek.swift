//
//  glowefek.swift
//  Camera
//
//  Created by Gilang Ramadhan on 07/05/25.
//

import SwiftUI
struct GlowingButton: View {
    @State private var isGlowing = true
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Matikan efek glow saat diklik
            withAnimation(.easeOut(duration: 0.3)) {
                isGlowing = false
                isPressed = true
            }
            
            // Lakukan aksi yang diinginkan
           
        }) {
            ZStack {
                Circle()
                    .fill(isPressed ? Color.red : Color.red.opacity(0.7))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(
                        color: isGlowing ? .blue : .clear,
                        radius: isGlowing ? 20 : 0
                    )
                
                
            }
            
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 0.5).repeatForever()) {
                    isGlowing = true
            }
        }
    }
}

struct viewContent: View {
    var body: some View {
        VStack(spacing: 30) {
            GlowingButton()
        }
    }
}

#Preview {
    viewContent()
}
