//
//  EarningsViewModel.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/14/25.
//
import SwiftUI
import FirebaseFirestore

import Firebase

class EarningsViewModel: ObservableObject {
    @Published var totalEarnings: Double = 0.0
    @Published var completedRides: Int = 0
    @Published var bonuses: Double = 0.0

    private let db = Firestore.firestore()
    private var driverId: String

    init(driverId: String) {
        self.driverId = driverId
        fetchEarnings()
    }

    func fetchEarnings() {
        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("❌ Error fetching earnings: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.totalEarnings = data["totalEarnings"] as? Double ?? 0.0
                self.completedRides = data["completedRides"] as? Int ?? 0
                self.bonuses = data["bonuses"] as? Double ?? 0.0
                print("✅ Updated Earnings: \(self.totalEarnings), Completed Rides: \(self.completedRides)")
            }
        }
    }

    func updateEarnings(amount: Double) {
        let updatedEarnings = totalEarnings + amount
        let updatedRides = completedRides + 1
        
        db.collection("drivers").document(driverId).updateData([
            "totalEarnings": updatedEarnings,
            "completedRides": updatedRides
        ]) { error in
            if let error = error {
                print("❌ Error updating earnings: \(error.localizedDescription)")
            } else {
                print("✅ Earnings updated successfully")
                self.fetchEarnings() // 🔹 Ensure UI updates after saving
            }
        }
    }
}
