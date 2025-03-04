//
//  CryptoWalletView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//


import SwiftUI


struct CryptoWalletView: View {
    @StateObject private var binanceService = BinanceService()
    @State private var walletBalance: Double = 10000 // Simulated balance
    @State private var holdings: [String: Double] = ["BTC": 0.5, "ETH": 2.0]

    var totalPortfolioValue: Double {
        holdings.reduce(0) { total, asset in
            let price = binanceService.cryptoPrices[asset.key + "USDT"] ?? 0 // Append "USDT" to match BinanceService symbols
            return total + (price * asset.value)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("💰 Crypto Wallet")
                    .font(.title)
                    .fontWeight(.bold)
                
                // ✅ Display crypto prices
                List(binanceService.cryptoPrices.sorted(by: { $0.key < $1.key }), id: \.key) { symbol, price in
                    HStack {
                        Text(symbol.replacingOccurrences(of: "USDT", with: "")) // Clean symbol name
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", price))")
                            .foregroundColor(.green)
                    }
                }
                
                // ✅ Refresh Prices
                Button(action: {
                    binanceService.fetchAllCryptoPrices()
                }) {
                    Text("Refresh Prices")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            
                Text("Total Portfolio Value")
                    .font(.headline)
                    .foregroundColor(.gray)

                Text("$\(String(format: "%.2f", totalPortfolioValue))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                List {
                    ForEach(holdings.keys.sorted(), id: \.self) { symbol in
                        if let price = binanceService.cryptoPrices[symbol + "USDT"] { // Append "USDT" to match BinanceService symbols
                            CryptoWalletRow(symbol: symbol, price: price, amount: holdings[symbol]!)
                        }
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()
            }
            .padding()
            .onAppear {
                binanceService.fetchAllCryptoPrices() // Call directly on binanceService, not $binanceService
            }
            .navigationBarTitle("Crypto Wallet", displayMode: .inline)
        }
    }
}

// MARK: - Crypto Wallet Row
struct CryptoWalletRow: View {
    let symbol: String
    let price: Double
    let amount: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.bold)

                Text("\(amount) \(symbol)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("$\(String(format: "%.2f", price * amount))")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CryptoWalletView()
}



/*struct CryptoWalletView: View {
    @StateObject private var binanceService = BinanceService()
    @State private var walletBalance: Double = 10000 // Simulated balance
    @State private var holdings: [String: Double] = ["BTC": 0.5, "ETH": 2.0]

    var totalPortfolioValue: Double {
        holdings.reduce(0) { total, asset in
            let price = binanceService.cryptoPrices[asset.key] ?? 0
            return total + (price * asset.value)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("💰 Crypto Wallet")
                    .font(.title)
                    .fontWeight(.bold)
                
                // ✅ Display crypto prices
                List(binanceService.cryptoPrices.sorted(by: { $0.key < $1.key }), id: \.key) { symbol, price in
                    HStack {
                        Text(symbol.replacingOccurrences(of: "USDT", with: "")) // Clean symbol name
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", price))")
                            .foregroundColor(.green)
                    }
                }
                
                // ✅ Refresh Prices
                Button(action: {
                    binanceService.fetchAllCryptoPrices
                }) {
                    Text("Refresh Prices")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            

                Text("Total Portfolio Value")
                    .font(.headline)
                    .foregroundColor(.gray)

                Text("$\(String(format: "%.2f", totalPortfolioValue))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                List {
                    ForEach(holdings.keys.sorted(), id: \.self) { symbol in
                        if let price = binanceService.cryptoPrices[symbol] {
                            CryptoWalletRow(symbol: symbol, price: price, amount: holdings[symbol]!)
                        }
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()
            }
            .padding()
            .onAppear {
                binanceService.fetchAllCryptoPrices
            }
            .navigationBarTitle("Crypto Wallet", displayMode: .inline)
        }
    }
}

// MARK: - Crypto Wallet Row
struct CryptoWalletRow: View {
    let symbol: String
    let price: Double
    let amount: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.bold)

                Text("\(amount) \(symbol)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("$\(String(format: "%.2f", price * amount))")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
}*/

