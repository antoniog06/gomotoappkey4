//
//  RideHistoryView.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
//


import SwiftUI

struct RideHistoryView: View {
    @State private var rides = [
        ("12/19/2024", "Completed", "$10.00"),
        ("12/18/2024", "Cancelled", "$0.00"),
        ("12/17/2024", "Completed", "$20.00")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Ride History")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            List(rides, id: \.0) { ride in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Date: \(ride.0)")
                        Text("Status: \(ride.1)")
                            .foregroundColor(ride.1 == "Completed" ? .green : .red)
                    }
                    Spacer()
                    Text("\(ride.2)")
                        .font(.headline)
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()
        }
        .padding()
    }
}

struct RideHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        RideHistoryView()
    }
}