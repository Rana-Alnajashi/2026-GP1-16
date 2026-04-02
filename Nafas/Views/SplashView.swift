//
//  SplashView.swift
//  Nafas
//
//  Created by Rana Alngashy on 02/04/2026.
//


import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            if isActive {
                // Transition to your main app flow
                RootView()
            } else {
                // Splash Screen UI
                ZStack {
                    Color.nafasBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        NafasLogoMark(size: 120)
                            .scaleEffect(scale)
                        
                        Text("app_name")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(Color.nafasPrimary)
                    }
                    .opacity(opacity)
                }
                .onAppear {
                    // 1. Animate the logo and text fading/scaling in
                    withAnimation(.easeOut(duration: 1.2)) {
                        self.opacity = 1.0
                        self.scale = 1.0
                    }
                    
                    // 2. Wait 5 seconds, then transition to RootView
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
