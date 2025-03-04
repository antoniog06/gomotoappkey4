//
//  CashierLocator.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import SwiftUI
import FirebaseFirestore
import CoreLocation
import Firebase

// MARK: - Cashier Locator Service
class CashierLocator {
    private let db = Firestore.firestore()

    func findNearbyCashiers(userLocation: CLLocationCoordinate2D, completion: @escaping ([Cashier]) -> Void) {
        db.collection("cashiers")
            .whereField("status", isEqualTo: "available")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching cashiers: \(error.localizedDescription)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("❌ No cashiers found.")
                    completion([])
                    return
                }

                var cashiers: [Cashier] = []

                for document in documents {
                    let data = document.data()

                    // Safely extract location dictionary
                    guard let locationData = data["location"] as? [String: Double],
                          let latitude = locationData["latitude"],
                          let longitude = locationData["longitude"] else {
                        print("⚠️ Invalid or missing location data for cashier: \(document.documentID)")
                        continue
                    }

                    let cashierLocation = CLLocation(latitude: latitude, longitude: longitude)
                    let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let distance = userCLLocation.distance(from: cashierLocation) / 1000 // Convert to km

                    if distance <= 5 { // Only show cashiers within 5 km
                        let cashier = Cashier(data: data, id: document.documentID)
                        cashiers.append(cashier)
                    }
                }

                completion(cashiers)
            }
    }
}

// MARK: - Cashier Model
struct Cashier: Identifiable {
    let id: String
    let userID: String
    let availableCash: Double
    let location: CLLocationCoordinate2D
    let status: String

    init(data: [String: Any], id: String) {
        self.id = id
        self.userID = data["userID"] as? String ?? ""
        self.availableCash = data["availableCash"] as? Double ?? 0.0

        // Safe extraction of location data
        if let locData = data["location"] as? [String: Double],
           let latitude = locData["latitude"],
           let longitude = locData["longitude"] {
            self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            self.location = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0) // Default if missing
        }

        self.status = data["status"] as? String ?? "available"
    }
}
/*import SwiftUI
import FirebaseFirestore
import CoreLocation
import Firebase

class CashierLocator {
    private let db = Firestore.firestore()
    
    
    
    
    class CashierLocator {
        private let db = Firestore.firestore()
        
        func findNearbyCashiers(userLocation: CLLocationCoordinate2D, completion: @escaping ([Cashier]) -> Void) {
            db.collection("cashiers")
                .whereField("status", isEqualTo: "available")
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("❌ Error fetching cashiers: \(error.localizedDescription)")
                        completion([])
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("❌ No cashiers found.")
                        completion([])
                        return
                    }
                    
                    var cashiers: [Cashier] = []
                    
                    for document in documents {
                        let data = document.data()
                        
                        // Safely extract location dictionary
                        guard let locationData = data["location"] as? [String: Double],
                              let latitude = locationData["latitude"],
                              let longitude = locationData["longitude"] else {
                            print("⚠️ Invalid or missing location data for cashier: \(document.documentID)")
                            continue
                        }
                        
                        let cashierLocation = CLLocation(latitude: latitude, longitude: longitude)
                        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                        
                        let distance = userCLLocation.distance(from: cashierLocation) / 1000 // Convert to km
                        
                        if distance <= 5 { // Filter only cashiers within 5 km
                            let cashier = Cashier(data: data, id: document.documentID)
                            cashiers.append(cashier)
                        }
                    }
                    
                    completion(cashiers)
                }
        }
    }
}
struct Cashier: Identifiable {
    let id: String
    let userID: String
    let availableCash: Double
    let location: CLLocationCoordinate2D
    let status: String

    init(data: [String: Any], id: String) {
        self.id = id
        self.userID = data["userID"] as? String ?? ""
        self.availableCash = data["availableCash"] as? Double ?? 0.0
        let locData = data["location"] as? [String: Double] ?? [:]
        self.location = CLLocationCoordinate2D(latitude: locData["latitude"]!, longitude: locData["longitude"]!)
        self.status = data["status"] as? String ?? "available"
    }
}
import FirebaseFirestore
import CoreLocation

class CashierLocator {
    private let db = Firestore.firestore()

    func findNearbyCashiers(userLocation: CLLocationCoordinate2D, completion: @escaping ([Cashier]) -> Void) {
        db.collection("cashiers")
            .whereField("status", isEqualTo: "available")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching cashiers: \(error.localizedDescription)")
                    completion([])
                    return
                }

                var cashiers: [Cashier] = []

                for document in snapshot!.documents {
                    let data = document.data()
                    guard let locationDict = data["location"] as? [String: Double],
                          let latitude = locationDict["latitude"],
                          let longitude = locationDict["longitude"] else {
                        continue
                    }

                    let cashierLocation = CLLocation(latitude: latitude, longitude: longitude)
                    let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let distance = userCLLocation.distance(from: cashierLocation) / 1000 // Convert to km

                    if distance <= 5 { // Only show cashiers within 5 km
                        let cashier = Cashier(data: data, id: document.documentID)
                        cashiers.append(cashier)
                    }
                }

                completion(cashiers)
            }
    }
}*/
