//
//  FirestoreRideService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/8/25.
//

import CoreLocation
import Firebase
import Foundation
import FirebaseFirestore

class FirestoreRideService {
    private let db = Firestore.firestore()

    // Add a ride with a data dictionary
    func addRide(data: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("rides").addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error)) // Pass the error back to the caller
            } else {
                completion(.success("Ride successfully added")) // Pass a success message back
            }
        }
    }

    // Add a ride with explicitly passed parameters
    func addRide(
        passengerId: String,
        passengerName: String,
        pickupLocation: GeoPoint,
        dropoffLocation: GeoPoint,
        status: String,
        fareAmount: Double?,
        estimatedTime: String?,
        distance: Double?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var rideData: [String: Any] = [
            "passengerId": passengerId,
            "passengerName": passengerName,
            "pickupLocation": pickupLocation,
            "dropoffLocation": dropoffLocation,
            "status": status,
            "timestamp": FieldValue.serverTimestamp()
        ]

        // Add optional fields
        if let fareAmount = fareAmount {
            rideData["fareAmount"] = fareAmount
        }
        if let estimatedTime = estimatedTime {
            rideData["estimatedTime"] = estimatedTime
        }
        if let distance = distance {
            rideData["distance"] = distance
        }

        db.collection("rides").addDocument(data: rideData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Ride successfully added"))
            }
        }
    }



    // Fetch a ride
    func fetchRide(rideId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("rides").document(rideId).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists, let data = document.data() {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Ride not found."])))
            }
        }
    }

    // Update a ride
    func updateRideStatus(rideId: String, newStatus: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("rides").document(rideId).updateData(["status": newStatus]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Delete a ride
    func deleteRide(rideId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("rides").document(rideId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    // listen for driver location
    func listenForDriverLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let driverId = "driver123" // Replace with the actual driver ID
        Firestore.firestore().collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for driver location: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                completion(nil)
                return
            }
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            completion(location)
        }
    }
    
}

