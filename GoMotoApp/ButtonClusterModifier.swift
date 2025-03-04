//
//  ButtonClusterModifier.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import SwiftUI

// Step 1: Define a custom ViewModifier
struct ButtonClusterModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1 : 0.5)
            .opacity(isActive ? 1 : 0)
            .rotationEffect(.degrees(isActive ? 0 : -45))
    }
}

// Step 2: Extend AnyTransition to include the custom transition
extension AnyTransition {
    static var buttonCluster: AnyTransition {
        .modifier(
            active: ButtonClusterModifier(isActive: true),
            identity: ButtonClusterModifier(isActive: false)
        )
    }
}