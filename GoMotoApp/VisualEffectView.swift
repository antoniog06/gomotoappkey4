//
//  VisualEffectView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import SwiftUI
import UIKit

struct VisualEffectView: UIViewRepresentable {
    let effect: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: effect))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
struct NeumorphicShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 5, y: 5)
            .shadow(color: Color.white.opacity(0.7), radius: 5, x: -5, y: -5)
    }
}
