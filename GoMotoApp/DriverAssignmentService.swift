//
//  DriverAssignmentService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import SwiftUI
import Firebase
import FirebaseFirestore



class DriverAssignmentService {
    private let db = Firestore.firestore()

    func assignDriverToOrder(orderID: String) {
        db.collection("drivers")
            .whereField("status", isEqualTo: "available")
            .order(by: "location", descending: false) // Sort by nearest
            .limit(to: 1)
            .getDocuments { [weak self] (snapshot, error) in  // ✅ Use `[weak self]` to prevent retain cycles
                guard let self = self else { return } // ✅ Ensure `self` is still available
                if let error = error {
                    print("❌ Error finding driver: \(error.localizedDescription)")
                    return
                }

                guard let driver = snapshot?.documents.first else {
                    print("⚠️ No available drivers found.")
                    return
                }

                let driverID = driver.documentID

                // ✅ Explicitly use `self.db` inside closure
                self.db.collection("orders").document(orderID).updateData([
                    "driverID": driverID,
                    "status": "driver_assigned"
                ]) { error in
                    if let error = error {
                        print("❌ Error assigning driver: \(error.localizedDescription)")
                    } else {
                        print("✅ Driver (\(driverID)) assigned to order (\(orderID))")
                    }
                }
            }
    }
}
