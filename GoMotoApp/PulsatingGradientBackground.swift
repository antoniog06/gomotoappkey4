//
//  PulsatingGradientBackground.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//


import SwiftUI

struct PulsatingGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.5)
        .edgesIgnoringSafeArea(.all)
        .blur(radius: 20)
        .animation(
            Animation.easeInOut(duration: 3)
                .repeatForever(autoreverses: true),
            value: animateGradient
        )
        .onAppear {
            animateGradient.toggle()
        }
    }
}

