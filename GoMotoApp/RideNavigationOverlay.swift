//
//  RideNavigationOverlay.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import SwiftUI

struct RideNavigationOverlay: View {
    let ride: RideRequest
    
    var body: some View {
        VStack {
            Text("Navigation to: \(ride.dropoffAddress ?? "Unknown")")
                .font(.headline)
                .padding()
            
            Button(action: {
                print("Simulating navigation start")
            }) {
                Text("Start Navigation")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
        .shadow(radius: 5)
    }
}