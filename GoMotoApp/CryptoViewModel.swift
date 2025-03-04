//
//  CryptoViewModel.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/25/25.
//
/*import SwiftUI
import Charts
import FirebaseFirestore


// CryptoViewModel (as provided in your earlier message)
class CryptoViewModel: ObservableObject {
    @Published var selectedCrypto: String = "BTC"
    @Published var prices: [KlineData] = []
    @Published var selectedTimeframe: String = "1h"
    @Published var showCandlestick: Bool = true
    @Published var isLoading: Bool = false
    @Published var walletBalance: Double = 10000
    @Published var tradeAmount: String = ""
    @Published var isBuying: Bool = true
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var holdings: [String: Double] = ["BTC": 0.5, "ETH": 2.0]
    @Published private var binanceService = BinanceService()

    func executeTrade(isBuying: Bool) {
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
}
*/


import SwiftUI
import Charts
import FirebaseFirestore





// CryptoViewModel for centralized state management
class CryptoViewModel: ObservableObject {
    @Published var selectedCrypto: String = "BTC"
    @Published var prices: [KlineData] = []
    @Published var selectedTimeframe: String = "1D" // Default to 1D for consistency with chart
    @Published var showCandlestick: Bool = true
    @Published var isLoading: Bool = false
    @Published var walletBalance: Double = 10000
    @Published var tradeAmount: String = ""
    @Published var isBuying: Bool = true
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var holdings: [String: Double] = ["BTC": 0.5, "ETH": 2.0, "SHIB": 1000000.0] // Added SHIB for example
    
    @Published private var binanceService = BinanceService()

    func executeTrade(isBuying: Bool) {
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
}
