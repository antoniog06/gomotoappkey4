//
//  FloatingCardEffect.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//


import SwiftUI

struct FloatingCardEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .scaleEffect(1.02)
            .animation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
    }
}

extension View {
    func floatingCardEffect() -> some View {
        self.modifier(FloatingCardEffect())
    }
}