//
//  PayoutRow.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//


import SwiftUI

struct PayoutRow: View {
    let payout: Payout // Ensure `PayoutModel` exists

    var body: some View {
        HStack {
           VStack(alignment: .leading) {
                        Text("Payout ID: \(payout.id)")
                        Text("Amount: \(payout.amount, specifier: "%.2f")")
                    }
                
            
            Spacer()
            Text(payout.status)
                .font(.footnote)
                .foregroundColor(payout.status == "Pending" ? .orange : .green)
        }
        .padding()
    }
}

// ✅ Ensure `PayoutModel` exists
struct PayoutModel: Identifiable {
    let id = UUID()
    let driverID: String
    let amount: Double
    let status: String
}
