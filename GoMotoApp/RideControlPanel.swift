//
//  RideControlPanel.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import SwiftUI

struct RideControlPanel: View {
    let ride: RideRequest
    let onComplete: () -> Void
    let onEmergency: () -> Void

    var body: some View {
        HStack {
            Button(action: onComplete) {
                Text("Complete Ride")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Button(action: onEmergency) {
                Text("Emergency")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
        .shadow(radius: 5)
    }
}