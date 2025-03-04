//
//  CryptoService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import LocalAuthentication
import SwiftUI
import FirebaseFirestore

class CryptoService {
    private let db = Firestore.firestore()

    func buyCrypto(userID: String, amountUSD: Double, cryptoType: String) {
        let conversionRate = getCryptoRate(cryptoType: cryptoType) // Assume this fetches real-time prices
        let cryptoAmount = amountUSD / conversionRate

        let walletRef = db.collection("crypto_wallets").document(userID)

        walletRef.updateData([
            "balances.\(cryptoType)": FieldValue.increment(cryptoAmount),
            "transactions": FieldValue.arrayUnion([
                ["type": "buy", "amount": cryptoAmount, "currency": cryptoType, "date": Timestamp(date: Date())]
            ])
        ]) { error in
            if let error = error {
                print("Error buying crypto: \(error.localizedDescription)")
            } else {
                print("Successfully bought \(cryptoAmount) \(cryptoType)")
            }
        }
    }
    
    func getCryptoRate(cryptoType: String) -> Double {
        // Fetch crypto rates from an API
        return 50000.0 // Example BTC price
    }

    func getStockPrice(stockSymbol: String) -> Double {
        // Fetch stock prices from an API
        return 150.0 // Example AAPL price
    }
    
    
    func sellCrypto(userID: String, amount: Double, cryptoType: String) {
        let conversionRate = getCryptoRate(cryptoType: cryptoType)
        let amountInUSD = amount * conversionRate

        let walletRef = db.collection("crypto_wallets").document(userID)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let walletSnapshot = try transaction.getDocument(walletRef)

                let currentBalance = walletSnapshot.data()?["balances.\(cryptoType)"] as? Double ?? 0.0

                if currentBalance < amount {
                    errorPointer?.pointee = NSError(domain: "Crypto", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient balance"])
                    return nil
                }

                transaction.updateData([
                    "balances.\(cryptoType)": currentBalance - amount,
                    "transactions": FieldValue.arrayUnion([
                        ["type": "sell", "amount": amount, "currency": cryptoType, "date": Timestamp(date: Date())]
                    ])
                ], forDocument: walletRef)

                return nil
            } catch {
                errorPointer?.pointee = NSError(domain: "Crypto", code: 500, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
                return nil
            }
        }) { (success, error) in
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                print("Successfully sold \(amount) \(cryptoType) for $\(amountInUSD)")
            }
        }
    }
   
}
