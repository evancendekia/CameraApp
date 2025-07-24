//
//  CameraPermissionView.swift
//  Snaptify
//
//  Created by Gilang Ramadhan on 19/07/25.
//

import SwiftUI

struct CameraPermissionView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Please allow camera permission")
                .font(.body)
                .foregroundColor(Color.white)
                .padding(.top, 33)
            
            (
                Text("Snaptify")
                    .font(.subheadline)
                    .foregroundStyle(Color.orange)
                
                +
                
                Text(" requires camera access to function properly to capture your precious moments.")
                    .font(.subheadline)
            )
            .multilineTextAlignment(.center)
            .padding(.top, 16)
            .padding(.horizontal)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            } label: {
                    Text("Open settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.top, 37)
            Spacer()
        }
        .padding(.horizontal)
        
    }
}

#Preview {
    CameraPermissionView()
}
