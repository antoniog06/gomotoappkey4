//
//  RideView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//


import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct RideView: View {
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var selectedRideType: RideType = .car
    @State private var estimatedFare: Double = 0.0
    @State private var isRequestingRide = false
    @State private var rideConfirmed = false
    @State private var rideID: String?

    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Request a Ride").font(.largeTitle).bold()

            // Pickup & Dropoff Fields
            TextField("Enter Pickup Location", text: $pickupLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Enter Dropoff Location", text: $dropoffLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Ride Type Selector
            Picker("Ride Type", selection: $selectedRideType) {
                Text("Car").tag(RideType.car)
                Text("Motorcycle").tag(RideType.motorcycle)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Estimate Fare Button
            Button("Estimate Fare") {
                estimatedFare = calculateFare()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Estimated Fare Display
            if estimatedFare > 0 {
                Text("Estimated Fare: $\(estimatedFare, specifier: "%.2f")")
                    .font(.title2)
                    .padding()
            }

            // Request Ride Button
            Button(isRequestingRide ? "Requesting..." : "Request Ride") {
                requestRide()
            }
            .disabled(isRequestingRide || pickupLocation.isEmpty || dropoffLocation.isEmpty)
            .padding()
            .background(isRequestingRide ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Confirmation Message
            if rideConfirmed {
                Text("Ride Confirmed! Ride ID: \(rideID ?? "N/A")")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}

// MARK: - 🚗 Ride Logic
extension RideView {
    enum RideType {
        case car, motorcycle
    }

    private func calculateFare() -> Double {
        let baseFare = selectedRideType == .car ? 5.0 : 3.0
        let distanceFactor = Double.random(in: 2...10) // Simulated distance
        return baseFare + (distanceFactor * 1.5)
    }

    private func requestRide() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isRequestingRide = true

        let rideData: [String: Any] = [
            "userID": userId,
            "pickup": pickupLocation,
            "dropoff": dropoffLocation,
            "rideType": selectedRideType == .car ? "Car" : "Motorcycle",
            "fare": estimatedFare,
            "status": "requested",
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("rides").addDocument(data: rideData) { error in
            isRequestingRide = false
            if let error = error {
                print("⚠️ Ride request failed: \(error.localizedDescription)")
            } else {
                rideConfirmed = true
                rideID = rideData["rideID"] as? String
                print("✅ Ride successfully requested!")
            }
        }
    }
}