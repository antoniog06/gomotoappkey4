//
//  MapPulseEffect.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import SwiftUI

struct MapPulseEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.05)
            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
    }
}

extension View {
    func mapPulseEffect() -> some View {
        self.modifier(MapPulseEffect())
    }
}
