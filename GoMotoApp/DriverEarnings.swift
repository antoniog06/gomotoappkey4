//
//  DriverEarnings.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.

//

import Foundation
import SwiftUI
import FirebaseFirestore

struct DriverEarnings: Codable {
    struct Metrics: Codable, Equatable {
        var totalEarnings: Double
        var completedRides: Int
        var bonuses: Double
        var unreadMessages: Int
        

        // Default instance for initialization
        static var `default`: Metrics {
            return Metrics(
                totalEarnings: 0.0,
                completedRides: 0,
                bonuses: 0.0,
                unreadMessages: 0 )
               
            
        }
        
        static func == (lhs: Metrics, rhs: Metrics) -> Bool {
            return lhs.totalEarnings == rhs.totalEarnings &&
                   lhs.completedRides == rhs.completedRides &&
                   lhs.bonuses == rhs.bonuses &&
                   lhs.unreadMessages == rhs.unreadMessages
                  
        }
        
        // Computed property to get total earnings including bonuses
        var totalWithBonuses: Double {
            totalEarnings + bonuses
        }
        
        // Function to safely update earnings
        mutating func updateEarnings(newEarnings: Double, newBonuses: Double) {
            totalEarnings += newEarnings
            bonuses += newBonuses
        }
        
        // Function to update completed rides count
        mutating func incrementCompletedRides() {
            completedRides += 1
        }
    }
    
    var metrics: Metrics
    
    // Default initializer with Firestore snapshot support
    init(snapshot: DocumentSnapshot? = nil) {
        let data = snapshot?.data() as? [String: Any] ?? [:]
        self.metrics = Metrics(
            totalEarnings: data["totalEarnings"] as? Double ?? 0.0,
            completedRides: data["completedRides"] as? Int ?? 0,
            bonuses: data["bonuses"] as? Double ?? 0.0,
            unreadMessages: data["unreadMessages"] as? Int ?? 0
            )
    
        
    }
    
    // Convert struct into dictionary for Firestore updates
    func toDictionary() -> [String: Any] {
        return [
            "totalEarnings": metrics.totalEarnings,
            "completedRides": metrics.completedRides,
            "bonuses": metrics.bonuses,
            "unreadMessages": metrics.unreadMessages,
        
        ]
    }
   
    
    // Function to update Firestore with new earnings data
    func updateFirestore(for driverId: String) {
        let db = Firestore.firestore()
        let data = toDictionary()
        
        print("Updating Firestore for Driver: \(driverId) with data: \(data)") // Debug log
        
        db.collection("drivers").document(driverId).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Error updating driver earnings: \(error.localizedDescription)")
            } else {
                print("✅ Driver earnings updated successfully!")
            }
        }
    }
}

/*import Foundation
import SwiftUI
import FirebaseFirestore


struct DriverEarnings: Codable {
    struct Metrics: Codable, Equatable {
        var totalEarnings: Double
        let completedRides: Int
        var bonuses: Double
        var unreadMessages: Int
        
        // Default initializer
        static var `default`: Metrics {
            return Metrics(
                totalEarnings: 0.0,
                completedRides: 0,
                bonuses: 0.0,
                unreadMessages: 0
            )
        }
        
        static func == (lhs: Metrics, rhs: Metrics) -> Bool {
            return lhs.totalEarnings == rhs.totalEarnings &&
            lhs.completedRides == rhs.completedRides &&
            lhs.bonuses == rhs.bonuses &&
            lhs.unreadMessages == rhs.unreadMessages
        }
    
    // Computed property to get total earnings including bonuses
        var totalWithBonuses: Double {
            return totalEarnings + bonuses
        }
        
        // Method to update earnings safely
        mutating func updateEarnings(newEarnings: Double, newBonuses: Double) {
            self.totalEarnings += newEarnings
            self.bonuses += newBonuses
        }
    }
    
    var metrics: Metrics
    
    // Default initializer with Firestore snapshot support
    init(snapshot: DocumentSnapshot? = nil) {
        let data = snapshot?.data() as? [String: Any] ?? [:]
        self.metrics = Metrics(
            totalEarnings: data["totalEarnings"] as? Double ?? 0.0,
            completedRides: data["completedRides"] as? Int ?? 0,
            bonuses: data["bonuses"] as? Double ?? 0.0,
            unreadMessages: data["unreadMessages"] as? Int ?? 0
            
        )
    }
    
    // Function to convert struct into dictionary for Firestore updates
    func toDictionary() -> [String: Any] {
        return [
            "totalEarnings": metrics.totalEarnings,
            "completedRides": metrics.completedRides,
            "bonuses": metrics.bonuses,
            "unreadMessages": metrics.unreadMessages
        ]
    }
}*/
