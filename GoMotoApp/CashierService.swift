//
//  CashierService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import FirebaseFirestore
import CoreLocation

class CashierService {
    private let db = Firestore.firestore()

    func registerAsCashier(userID: String, availableCash: Double, location: CLLocationCoordinate2D) {
        let cashierData: [String: Any] = [
            "userID": userID,
            "availableCash": availableCash,
            "location": [
                "latitude": location.latitude,
                "longitude": location.longitude
            ],
            "status": "available"
        ]

        db.collection("cashiers").document(userID).setData(cashierData) { error in
            if let error = error {
                print("Error registering as cashier: \(error.localizedDescription)")
            } else {
                print("User \(userID) is now a cashier!")
            }
        }
    }
}