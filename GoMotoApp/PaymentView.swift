//
//  PaymentView.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
//


import SwiftUI

struct PaymentView: View {
    @State private var paymentMethod: String = "Credit Card"
    @State private var transactionHistory: [String] = [
        "Paid $10 to GoMoto",
        "Refund of $5",
        "Paid $20 to GoMoto"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Payments")
                .font(.title)
                .fontWeight(.bold)

            Picker("Payment Method", selection: $paymentMethod) {
                Text("Credit Card").tag("Credit Card")
                Text("PayPal").tag("PayPal")
                Text("Apple Pay").tag("Apple Pay")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Text("Transaction History")
                .font(.headline)
                .padding(.top)

            List(transactionHistory, id: \.self) { transaction in
                Text(transaction)
            }

            Spacer()
        }
        .padding()
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView()
    }
}