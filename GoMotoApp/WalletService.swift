//
//  WalletService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import FirebaseFirestore
import Stripe
import StripePayments
import StripePaymentSheet
import StripeFinancialConnections

class WalletService {
    private let db = Firestore.firestore()

    // 🚀 Send Money to Another User
    func sendMoney(fromUser: String, toUser: String, amount: Double) {
        let senderRef = db.collection("wallets").document(fromUser)
        let receiverRef = db.collection("wallets").document(toUser)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let senderSnapshot = try transaction.getDocument(senderRef)
                let receiverSnapshot = try transaction.getDocument(receiverRef)
                
                guard let senderBalance = senderSnapshot.data()?["balance"] as? Double, senderBalance >= amount else {
                    errorPointer?.pointee = NSError(domain: "Wallet", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient funds"])
                    return nil
                }
                
                let receiverBalance = receiverSnapshot.data()?["balance"] as? Double ?? 0.0
                
                transaction.updateData(["balance": senderBalance - amount], forDocument: senderRef)
                transaction.updateData(["balance": receiverBalance + amount], forDocument: receiverRef)
                
                return nil
            } catch {
                errorPointer?.pointee = NSError(domain: "Wallet", code: 500, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
                return nil
            }
        }) { (success, error) in
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                print("Transaction successful: \(amount) sent from \(fromUser) to \(toUser)")
            }
        }
    }

    // 🚀 Withdraw Money to Bank (Stripe)
    func withdrawToBank(userID: String, amount: Double) {
        let url = URL(string: "https://us-central1-gomoto-c9e9f.cloudfunctions.net/requestPayout")! // ✅ Replace with your Firebase function URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userID": userID,
            "amount": amount
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Payout failed: \(error.localizedDescription)")
                return
            }

            if let data = data,
               let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = jsonResponse["success"] as? Bool, success {
                print("✅ Payout of $\(amount) requested for \(userID)")
            } else {
                print("⚠️ Payout request failed: \(String(describing: response))")
            }
        }.resume()
    }
}



/*   func withdrawToBank(userID: String, amount: Double) {
       let userRef = db.collection("wallets").document(userID)

       userRef.getDocument { (document, error) in
           if let document = document, document.exists {
               let balance = document.data()?["balance"] as? Double ?? 0.0

               if balance >= amount {
                   let payoutParams = STPPayoutParams()
                   payoutParams.amount = Int(amount * 100)
                   payoutParams.currency = "usd"
                   payoutParams.destination = userID // User’s Stripe bank account
                   payoutParams.method = .instant

                   let payoutRequest = STPPayout.create(withParams: payoutParams) { (payout, error) in
                       if let error = error {
                           print("Payout failed: \(error.localizedDescription)")
                       } else {
                           print("Payout of \(amount) sent to \(userID)")
                           userRef.updateData(["balance": balance - amount])
                       }
                   }
               } else {
                   print("Not enough funds to withdraw.")
               }
           }
       }
   }*/
