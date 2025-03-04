//
//  RefundService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import FirebaseFirestore

class RefundService {
    private let db = Firestore.firestore()
    
    // Request a refund (customer side)
    func requestRefund(orderID: String, customerID: String, reason: String) {
        db.collection("orders").document(orderID).updateData([
            "refundStatus": "pending"
        ]) { error in
            if let error = error {
                print("Error requesting refund: \(error.localizedDescription)")
            } else {
                print("Refund request submitted for order \(orderID)")
            }
        }
    }
    
    // Approve or deny refund (admin side)
    func processRefund(orderID: String, approve: Bool) {
        let orderRef = db.collection("orders").document(orderID)

        orderRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let driverID = data?["driverID"] as? String ?? ""
                let refundAmount = data?["orderAmount"] as? Double ?? 0.0

                if approve {
                    // Deduct refund amount from driver earnings
                    self.deductDriverEarnings(driverID: driverID, amount: refundAmount)
                    
                    // Update order as refunded
                    orderRef.updateData([
                        "refundStatus": "approved",
                        "refundAmount": refundAmount
                    ]) { error in
                        if let error = error {
                            print("Error processing refund: \(error.localizedDescription)")
                        } else {
                            print("Refund approved for order \(orderID). Driver earnings adjusted.")
                        }
                    }
                } else {
                    // Deny refund request
                    orderRef.updateData([
                        "refundStatus": "denied"
                    ]) { error in
                        if let error = error {
                            print("Error denying refund: \(error.localizedDescription)")
                        } else {
                            print("Refund denied for order \(orderID).")
                        }
                    }
                }
            }
        }
    }
    
    // Deduct refund amount from the driver's next earnings
    private func deductDriverEarnings(driverID: String, amount: Double) {
        let driverRef = db.collection("drivers").document(driverID)

        driverRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let currentEarnings = document.data()?["earnings"] as? Double ?? 0.0
                let updatedEarnings = max(0, currentEarnings - amount) // Prevent negative balance

                driverRef.updateData([
                    "earnings": updatedEarnings
                ]) { error in
                    if let error = error {
                        print("Error updating driver earnings: \(error.localizedDescription)")
                    } else {
                        print("Driver \(driverID) charged \(amount) for refund.")
                    }
                }
            }
        }
    }
}