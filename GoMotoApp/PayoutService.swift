//
//  PayoutService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import SwiftUI
import FirebaseFirestore
import Stripe

class PayoutService {
    private let db = Firestore.firestore()
    
    // 🚀 Schedule Weekly Payouts for Drivers
    func processWeeklyPayouts() {
        let currentDate = Date()
        let calendar = Calendar.current
        let nextPayoutDate = calendar.nextDate(after: currentDate, matching: DateComponents(weekday: 6), matchingPolicy: .nextTimePreservingSmallerComponents) // Every Friday
        
        db.collection("drivers").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching drivers: \(error.localizedDescription)")
                return
            }
            
            snapshot?.documents.forEach { document in
                let driverID = document.documentID
                let earnings = document.data()["weeklyEarnings"] as? Double ?? 0.0
                
                if earnings > 0 {
                    self.sendPayoutToDriver(driverID: driverID, amount: earnings)
                    
                    // Reset earnings for next week
                    self.db.collection("drivers").document(driverID).updateData(["weeklyEarnings": 0])
                }
            }
        }
    }
    
    // 🔹 Process Stripe Payouts
    private func sendPayoutToDriver(driverID: String, amount: Double) {
        guard let url = URL(string: "https://us-central1-gomoto-c9e9f.cloudfunctions.net/requestPayout") else {
            print("❌ Invalid payout URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payoutData: [String: Any] = [
            "driverID": driverID,
            "amount": amount
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payoutData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Payout failed for driver \(driverID): \(error.localizedDescription)")
                return
            }
            
            if let data = data,
               let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = jsonResponse["success"] as? Bool, success {
                print("✅ Payout of $\(amount) sent to driver \(driverID)")
            } else {
                print("⚠️ Payout request failed: \(String(describing: response))")
            }
        }.resume()
    }
}


      /*   private func sendPayoutToDriver(driverID: String, amount: Double) {
             let payoutParams = STPPayoutParams()
             payoutParams.amount = Int(amount * 100) // Convert to cents
             payoutParams.currency = "usd"
             payoutParams.destination = driverID // Driver's Stripe account
             payoutParams.method = .standard

             let payoutRequest = STPPayout.create(withParams: payoutParams) { (payout, error) in
                 if let error = error {
                     print("Payout failed for driver \(driverID): \(error.localizedDescription)")
                 } else {
                     print("Payout of $\(amount) sent to driver \(driverID)")
                 }
             }
         }*/
