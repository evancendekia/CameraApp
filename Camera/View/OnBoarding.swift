//
//  OnBoarding.swift
//  Camera
//
//  Created by acqmal on 5/13/25.
//

import SwiftUI

struct OnBoarding: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $selectedTab) {
                    ZStack {
                        Image("OnBoarding1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                        
                        VStack {
                            Spacer()
                            Text("Hands-Free & Natural Set your phone down and Snaptify will capture when you smile")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 32)
                                .padding(.horizontal)
                        }
                    }.tag(0)
                    
                    ZStack {
                        Image("OnBoarding2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                        
                        VStack {
                            Spacer()
                            Text("Perfect for Gathering Moments Ideal for hangouts, parties, and family time.")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 32)
                                .padding(.horizontal)
                        }
                        
                    }.tag(1)
                    
                }.tabViewStyle(PageTabViewStyle())
                    .frame(height: 570)
                Spacer()
                Button {
                    if selectedTab < 1 {
                        withAnimation {
                            selectedTab += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                }label: {
                    Text(selectedTab == 1 ? "See How It Works" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("SecondaryColor").opacity(0.85))
                        .cornerRadius(20)
                }.padding(.horizontal)
            }.toolbar{
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("")
                        Text("")
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Snaptify")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                }
            }
        }
           
    }
}

#Preview {
    OnBoarding()
}
