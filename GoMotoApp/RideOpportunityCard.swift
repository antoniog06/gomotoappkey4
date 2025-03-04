//
//  RideOpportunityCard.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import SwiftUI

struct RideOpportunityCard: View {
    let ride: RideRequest
    let acceptRide: () -> Void
    let declineRide: () -> Void

    var body: some View {
        VStack {
            Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                .font(.headline)
                .padding(.bottom, 2)

            Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                Button(action: acceptRide) {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: declineRide) {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
    }
}