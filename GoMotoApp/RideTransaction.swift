//
//  RideTransaction.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//


import SwiftUI
import FirebaseFirestore

struct RideTransaction: Identifiable, Decodable {
    var id: String
    let passengerName: String
    let passengerId: String
    let driverId: String?
    let driverName: String
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
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.passengerName = data["passengerName"] as? String ?? "Unknown"
        self.passengerId = data["passengerId"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String
        self.driverName = data["driverName"] as? String ?? "Unknown"
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
    }
    
    init(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        self.id = doc.documentID
        self.passengerName = data["passengerName"] as? String ?? "Unknown"
        self.passengerId = data["passengerId"] as? String ?? "Unknown"
        self.driverId = data["driverId"] as? String
        self.driverName = data["driverName"] as? String ?? "Unknown"
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
    }
}