//
//  QRPaymentView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import AVFoundation

import SwiftUI

struct QRPaymentView: View {
    @State private var scannedCode: String?
    @State private var amountToSend = ""

    var body: some View {
        VStack {
            Text("Scan QR Code to Pay")
                .font(.title)
                .padding()

            QRCodeScannerView(scannedCode: $scannedCode)
                .frame(height: 300)

            if let scannedCode = scannedCode {
                Text("Scanned User: \(scannedCode)")
                    .padding()

                TextField("Enter Amount", text: $amountToSend)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    WalletService().sendMoney(fromUser: "currentUserID", toUser: scannedCode, amount: Double(amountToSend) ?? 0.0)
                }) {
                    Text("Send Money")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }

            Spacer()
        }
    }
}
