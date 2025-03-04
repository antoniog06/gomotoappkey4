//
//  RideRequest.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/21/25.
//

import SwiftUI
import FirebaseFirestore

struct RideRequest: Identifiable, Decodable, Equatable {
    
    var id: String
    let passengerId: String
    let passengerName: String
    let driverId: String?
    let driverName: String?
    let pickupLocation: GeoPoint
    let dropoffLocation: GeoPoint
    let pickupAddress: String?
    let dropoffAddress: String?
    let status: String
    let fareAmount: Double?
    let distance: Double?
    let estimatedTime: Double?
    let paymentMethod: String?
    let timestamp: Timestamp?
    let baseFare: Double

    // 🔹 Initializer for Firestore Data
    init(id: String, data: [String: Any]) {
        
        self.id = id
        self.passengerId = data["passengerId"] as? String ?? "Unknown"
        self.passengerName = data["passengerName"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String
        self.driverName = data["driverName"] as? String
        self.pickupLocation = data["pickupLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.dropoffLocation = data["dropoffLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.pickupAddress = data["pickupAddress"] as? String ?? "Unknown"
        self.dropoffAddress = data["dropoffAddress"] as? String ?? "Unknown"
        self.status = data["status"] as? String ?? "Unknown"
        self.fareAmount = data["fareAmount"] as? Double
        self.distance = data["distance"] as? Double
        self.estimatedTime = data["estimatedTime"] as? Double ?? 2.0
        self.paymentMethod = data["paymentMethod"] as? String
        self.timestamp = data["timestamp"] as? Timestamp
        self.baseFare = data["baseFare"] as? Double ?? 5.0
    }

    // 🔹 Firestore Query Snapshot Initializer
    init(doc: QueryDocumentSnapshot) {
        self.init(id: doc.documentID, data: doc.data())
    }

    // ✅ Equatable conformance based on ID
    static func == (lhs: RideRequest, rhs: RideRequest) -> Bool {
        return lhs.id == rhs.id
    }

    // 🔹 Computed Property to Get Readable Date
    var formattedDate: String {
        guard let timestamp = timestamp else { return "Unknown Date" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: timestamp.dateValue())
    }
}
import FirebaseFirestore

struct Ride: Identifiable {
    var id: String
    let pickupLocation: GeoPoint
    let dropoffLocation: GeoPoint
    let status: String
    let passengerId: String
    let driverId: String?
    let estimatedTime: String?
    let fareAmount: Double?
    let distance: Double?
    let timestamp: Timestamp?

    // Firestore Initializer
    init(id: String, data: [String: Any]) {
        self.id = id
        self.pickupLocation = data["pickupLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.dropoffLocation = data["dropoffLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.status = data["status"] as? String ?? "Unknown"
        self.passengerId = data["passengerId"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String
        self.estimatedTime = data["estimatedTime"] as? String
        self.fareAmount = data["fareAmount"] as? Double
        self.distance = data["distance"] as? Double
        self.timestamp = data["timestamp"] as? Timestamp
    }

    // Firestore Query Snapshot Initializer
    init(doc: QueryDocumentSnapshot) {
        self.init(id: doc.documentID, data: doc.data())
    }
}


// no need for ride model
/*struct RideRequest: Identifiable, Decodable, Equatable {
    var id: String
    let passengerId: String
    let passengerName: String
    let driverId: String?
    let driverName: String?
    let pickupLocation: GeoPoint
    let dropoffLocation: GeoPoint
    let pickupAddress: String?
    let dropoffAddress: String?
    let status: String
    let fareAmount: Double?
    let distance: Double?
    let estimatedTime: String?
    let paymentMethod: String?
    let timestamp: Timestamp?
    let baseFare: Double // added basefare

    // 🔹 Unified Initializer (Dictionary-based)
    init(id: String, data: [String: Any]) {
        self.id = id
        self.passengerId = data["passengerId"] as? String ?? "Unknown"
        self.passengerName = data["passengerName"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String
        self.driverName = data["driverName"] as? String
        self.pickupLocation = data["pickupLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.dropoffLocation = data["dropoffLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.pickupAddress = data["pickupAddress"] as? String ?? "Unknown"
        self.dropoffAddress = data["dropoffAddress"] as? String ?? "Unknown"
        self.status = data["status"] as? String ?? "Unknown"
        self.fareAmount = data["fareAmount"] as? Double
        self.distance = data["distance"] as? Double
        self.estimatedTime = data["estimatedTime"] as? String
        self.paymentMethod = data["paymentMethod"] as? String
        self.timestamp = data["timestamp"] as? Timestamp
        self.baseFare = data["baseFare"] as? Double ?? 5.0
        
    }

    // 🔹 Firestore Query Initializer
    init(doc: QueryDocumentSnapshot) {
        self.init(id: doc.documentID, data: doc.data())
    }

    // ✅ Fixed Equatable conformance
    static func == (lhs: RideRequest, rhs: RideRequest) -> Bool {
        return lhs.id == rhs.id
    }
}
struct Ride: Identifiable, Decodable {
    var id: String
    let pickupLocation: GeoPoint
    let dropoffLocation: GeoPoint
    let status: String
    let passengerId: String
    let driverId: String?
    let estimatedTime: String?
    let fareAmount: Double?
    let distance: Double?
    let timestamp: Timestamp?

    init(id: String, data: [String: Any]) {
        self.id = id
        self.pickupLocation = data["pickupLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.dropoffLocation = data["dropoffLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.status = data["status"] as? String ?? "Unknown"
        self.passengerId = data["passengerId"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String
        self.estimatedTime = data["estimatedTime"] as? String
        self.fareAmount = data["fareAmount"] as? Double
        self.distance = data["distance"] as? Double
        self.timestamp = data["timestamp"] as? Timestamp
    }
}*/

