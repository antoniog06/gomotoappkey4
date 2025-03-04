//
//  CryptoPricesView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//


import SwiftUI

struct CryptoPricesView: View {
    @StateObject private var binanceService = BinanceService()

    var body: some View {
        NavigationView {
            VStack {
                Text("🔥 Crypto Market")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                List {
                    ForEach(binanceService.symbols, id: \.self) { symbol in
                        if let price = binanceService.cryptoPrices[symbol] {
                            CryptoRow(symbol: symbol, price: price)
                        } else {
                            ProgressView()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .onAppear {
                binanceService.fetchAllCryptoPrices()
            }
            .navigationBarTitle("Crypto Tracker", displayMode: .inline)
        }
    }
}

// MARK: - Crypto Row (Stylized)
struct CryptoRow: View {
    let symbol: String
    let price: Double

    var body: some View {
        HStack {
            Image(systemName: "bitcoinsign.circle.fill") // Replace with actual crypto logos
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("$\(String(format: "%.2f", price))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
}
