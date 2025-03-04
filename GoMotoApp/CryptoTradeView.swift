//
//  CryptoTradeView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//

import SwiftUI
import Charts
import Combine

struct CryptoTradeView: View {
    @ObservedObject var viewModel: CryptoViewModel
    @StateObject private var binanceService = BinanceService()
    @StateObject private var webSocketService = BinanceWebSocketService()
    
    @State private var walletBalance: Double = 10000
    
    @State private var selectedCrypto: String = "BTC"
    @State private var tradeAmount: String = ""
    @State private var isBuying: Bool = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var holdings: [String: Double] = ["BTC": 0.5, "ETH": 2.0]
    
    
    // State for chart-related bindings
    @State private var prices: [KlineData] = [] // Store OHLCV data
    @State private var selectedTimeframe: String = "1h" // Default timeframe
    @State private var showCandlestick: Bool = true // Default chart style
    @State private var isLoading: Bool = false // Loading state for chart
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("💰 Your Crypto Wallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Balance: $\(String(format: "%.2f", viewModel.walletBalance))")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                List {
                    ForEach(viewModel.holdings.keys.sorted(), id: \.self) { symbol in
                        if let price = binanceService.cryptoPrices[symbol] {
                            CryptoWalletRow(symbol: symbol, price: price, amount: viewModel.holdings[symbol]!)
                        }
                    }
                }
                
                // Buy/Sell UI
                VStack(spacing: 12) {
                    Picker("Select Crypto", selection: $viewModel.selectedCrypto) {
                        ForEach(binanceService.symbols, id: \.self) { symbol in
                            Text(symbol).tag(symbol)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Amount (in USD)", text: $viewModel.tradeAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Button(action: { viewModel.executeTrade(isBuying: true) }) {
                            Text("Buy \(viewModel.selectedCrypto)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: { viewModel.executeTrade(isBuying: false) }) {
                            Text("Sell \(viewModel.selectedCrypto)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                
                // Add NavigationLink to CryptoChartView
                NavigationLink(destination: CryptoChartView(
                    selectedCrypto: $viewModel.selectedCrypto,
                    prices: $viewModel.prices,
                    selectedTimeframe: $viewModel.selectedTimeframe,
                    showCandlestick: $viewModel.showCandlestick,
                    isLoading: $viewModel.isLoading
                )) {
                    Text("View Crypto Chart")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Crypto Trading")
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Trade Status"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    // ... rest of the code ...

               
    
        // Placeholder for CryptoWalletRow (you'll need to define this)
        struct CryptoWalletRow: View {
            let symbol: String
            let price: Double
            let amount: Double
            
            var body: some View {
                HStack {
                    Text(symbol)
                    Spacer()
                    Text("$\(String(format: "%.2f", price * amount))")
                        .foregroundColor(.gray)
                }
            }
        }
        
        // Placeholder for CryptoChartView (you'll need to define this fully)
        struct CryptoChartView: View {
            @Binding var selectedCrypto: String
            @Binding var prices: [KlineData]
            @Binding var selectedTimeframe: String
            @Binding var showCandlestick: Bool
            @Binding var isLoading: Bool
            
            var body: some View {
                Text("Chart for \(selectedCrypto) - Timeframe: \(selectedTimeframe)")
                    .navigationTitle("Crypto Chart")
            }
        }
    }

   
/*import SwiftUI

struct CryptoTradeView: View {
    @StateObject private var binanceService = BinanceService()
    @State private var walletBalance: Double = 10000
    @ObservedObject var viewModel: CryptoViewModel
    @State private var selectedCrypto: String = "BTC"
    @State private var tradeAmount: String = ""
    @State private var isBuying: Bool = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State  private var holdings: [String: Double] = ["BTC": 0.5, "ETH": 2.0]
    @StateObject private var webSocketService = BinanceWebSocketService()
    

    var body: some View {
        NavigationView {
            VStack {
                Text("💰 Your Crypto Wallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Balance: $\(String(format: "%.2f", walletBalance))")
                    .font(.headline)
                    .foregroundColor(.gray)

                List {
                    ForEach(holdings.keys.sorted(), id: \.self) { symbol in
                        if let price = binanceService.cryptoPrices[symbol] {
                            CryptoWalletRow(symbol: symbol, price: price, amount: holdings[symbol]!)
                        }
                    }
                }

                // Buy/Sell UI
                VStack(spacing: 12) {
                    Picker("Select Crypto", selection: $selectedCrypto) {
                        ForEach(binanceService.symbols, id: \.self) { symbol in
                            Text(symbol).tag(symbol)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Amount (in USD)", text: $tradeAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    HStack {
                        Button(action: { executeTrade(isBuying: true) }) {
                            Text("Buy \(selectedCrypto)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: { executeTrade(isBuying: false) }) {
                            Text("Sell \(selectedCrypto)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationBarTitle("Crypto Trading", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Trade Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    private func buyCrypto() {
        print("🟢 Buy button tapped!")

        guard let price = binanceService.cryptoPrices[selectedCrypto],
              let amount = Double(tradeAmount),
              amount > 0 else {
            print("❌ Invalid input: Price = \(binanceService.cryptoPrices[selectedCrypto] ?? 0), Amount = \(tradeAmount)")
            return
        }
        
        let cost = price * amount
        print("💰 Cost: \(cost), Wallet Balance: \(walletBalance)")

        if cost <= walletBalance {
            walletBalance -= cost
            holdings[selectedCrypto, default: 0] += amount
            print("✅ Purchase successful! New Wallet Balance: \(walletBalance), Holdings: \(holdings[selectedCrypto] ?? 0)")
        } else {
            print("❌ Insufficient funds! Needed: \(cost), Available: \(walletBalance)")
        }
    }
    // MARK: - Execute Buy/Sell Trade
    private func executeTrade(isBuying: Bool) {
        guard let amount = Double(tradeAmount), amount > 0 else {
            alertMessage = "Enter a valid amount."
            showAlert = true
            return
        }

        let cryptoPrice = binanceService.cryptoPrices[selectedCrypto] ?? 0
        let cryptoAmount = amount / cryptoPrice

        if isBuying {
            if walletBalance >= amount {
                walletBalance -= amount
                holdings[selectedCrypto, default: 0] += cryptoAmount
                alertMessage = "✅ Bought \(cryptoAmount) \(selectedCrypto) for $\(amount)."
            } else {
                alertMessage = "❌ Insufficient Balance!"
            }
        } else {
            if let ownedCrypto = holdings[selectedCrypto], ownedCrypto >= cryptoAmount {
                holdings[selectedCrypto]! -= cryptoAmount
                walletBalance += amount
                alertMessage = "✅ Sold \(cryptoAmount) \(selectedCrypto) for $\(amount)."
            } else {
                alertMessage = "❌ Insufficient \(selectedCrypto) to sell!"
            }
        }

        showAlert = true
    }
}*/
