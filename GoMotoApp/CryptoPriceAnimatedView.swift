//
//  CryptoPriceAnimatedView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//


import SwiftUI

struct CryptoPriceAnimatedView: View {
    @State private var price: Double = 25000.0
    @State private var isPriceUp = true

    var body: some View {
        VStack {
            Text("BTC/USD")
                .font(.headline)

            Text("$\(String(format: "%.2f", price))")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(isPriceUp ? .green : .red)
                .scaleEffect(isPriceUp ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: price)

            Button("Simulate Price Change") {
                let newPrice = Double.random(in: 24000...26000)
                isPriceUp = newPrice > price
                price = newPrice
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}