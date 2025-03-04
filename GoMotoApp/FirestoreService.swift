//
//  FirestoreService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import SwiftUI
import Firebase
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    func saveTransaction(transaction: AppTransaction) {
        let transactionData: [String: Any] = [
            "description": transaction.description,
            "amount": transaction.amount,
            "timestamp": Timestamp(date: transaction.date),
            "isCredit": transaction.isCredit,
            "adminFee": transaction.adminFee,
            "driverEarnings": transaction.driverEarnings
        ]

        db.collection("transactions").document(transaction.id).setData(transactionData) { error in
            if let error = error {
                print("Error saving transaction: \(error.localizedDescription)")
            } else {
                print("Transaction saved successfully!")
            }
        }
    }
  

    class FirestoreService {
        private let db = Firestore.firestore()

        func saveRideTransaction(distance: Double, duration: Double) {
            let pricing = PricingEngine.calculateRideFare(distanceInMiles: distance, durationInMinutes: duration)

            let rideData: [String: Any] = [
                "distance": distance,
                "duration": duration,
                "totalFare": pricing.totalFare,
                "adminFee": pricing.adminFee,
                "driverEarnings": pricing.driverEarnings,
                "timestamp": Timestamp(date: Date())
            ]

            db.collection("rides").addDocument(data: rideData) { error in
                if let error = error {
                    print("Error saving ride transaction: \(error.localizedDescription)")
                } else {
                    print("Ride transaction saved successfully!")
                }
            }
        }
    }
    func saveFoodDeliveryTransaction(orderAmount: Double, distance: Double) {
        let pricing = PricingEngine.calculateDeliveryFee(orderAmount: orderAmount, distanceInMiles: distance)

        let orderData: [String: Any] = [
            "orderAmount": orderAmount,
            "distance": distance,
            "totalFee": pricing.totalFee,
            "adminFee": pricing.adminFee,
            "driverEarnings": pricing.driverEarnings,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("deliveries").addDocument(data: orderData) { error in
            if let error = error {
                print("Error saving delivery transaction: \(error.localizedDescription)")
            } else {
                print("Food delivery transaction saved successfully!")
            }
        }
    }
}
