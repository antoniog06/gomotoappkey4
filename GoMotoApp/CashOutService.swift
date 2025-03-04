//
//  CashOutService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import FirebaseFirestore
import CoreLocation

class CashOutService {
    private let db = Firestore.firestore()
    
    func sendMoneyToCashier(recipientID: String, cashierID: String, amount: Double) {
        let recipientRef = db.collection("wallets").document(recipientID)
        let cashierRef = db.collection("wallets").document(cashierID)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let recipientSnapshot = try transaction.getDocument(recipientRef)
                let cashierSnapshot = try transaction.getDocument(cashierRef)
                
                let recipientBalance = recipientSnapshot.data()?["balance"] as? Double ?? 0.0
                let cashierBalance = cashierSnapshot.data()?["balance"] as? Double ?? 0.0
                
                if recipientBalance < amount {
                    errorPointer?.pointee = NSError(domain: "Wallet", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient funds"])
                    return nil
                }
                
                transaction.updateData(["balance": recipientBalance - amount], forDocument: recipientRef)
                transaction.updateData(["balance": cashierBalance + amount], forDocument: cashierRef)
                
                return nil
            } catch {
                errorPointer?.pointee = NSError(domain: "Wallet", code: 500, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
                return nil
            }
        }) { (success, error) in
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                print("Transaction successful: $\(amount) sent to Cashier (\(cashierID))")
            }
        }
        func confirmCashPickup(transactionID: String) {
            let transactionRef = db.collection("transactions").document(transactionID)
            
            transactionRef.updateData(["status": "completed"]) { error in
                if let error = error {
                    print("Error confirming cash pickup: \(error.localizedDescription)")
                } else {
                    print("Cash pickup confirmed!")
                }
            }
        }
    }
}
