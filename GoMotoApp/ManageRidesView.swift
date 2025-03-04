//
//  ManageRidesView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct ManageRidesView: View {
    @State private var rideRequests: [RideRequest] = [] // New ride requests
    @State private var assignedRides: [Ride] = []       // Rides assigned to the driver
    @State private var errorMessage: String = ""
    @State private var isAvailable: Bool = true
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                Toggle("Available for Rides", isOn: $isAvailable)
                    .onChange(of: isAvailable) { newValue in
                        updateDriverAvailability(isAvailable: newValue)
                    }
                    .padding()

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                List {
                    Section(header: Text("New Ride Requests")) {
                        if rideRequests.isEmpty {
                            Text("No new ride requests.")
                        } else {
                            ForEach(rideRequests) { request in
                                RideRequestRow(request: request)
                                    .onTapGesture {
                                        acceptRide(request: request)
                                    }
                            }
                        }
                    }

                    Section(header: Text("Your Assigned Rides")) {
                        if assignedRides.isEmpty {
                            Text("No assigned rides.")
                        } else {
                            ForEach(assignedRides) { ride in
                                RideRow(ride: ride)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Rides")
            .onAppear(perform: fetchRides)
        }
    }

    // Fetch both new ride requests and the driver’s assigned rides
    private func fetchRides() {
        fetchRideRequests()
        fetchAssignedRides()
    }

    private func fetchRideRequests() {
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching ride requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.rideRequests = []
                    return
                }

                self.rideRequests = documents.compactMap { doc -> RideRequest? in
                    let data = doc.data()
                    return RideRequest(id: doc.documentID, data: data)
                }
            }
    }

    private func fetchAssignedRides() {
        guard let driverId = Auth.auth().currentUser?.uid else {
            errorMessage = "Driver not authenticated."
            return
        }

        db.collection("rides")
            .whereField("driverId", isEqualTo: driverId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Error fetching assigned rides: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.assignedRides = []
                    return
                }

                self.assignedRides = documents.compactMap { doc -> Ride? in
                    let data = doc.data()
                    return Ride(id: doc.documentID, data: data)
                }
            }
    }

    // Accept a ride request
    private func acceptRide(request: RideRequest) {
        guard let driverId = Auth.auth().currentUser?.uid else { return }

        db.collection("rides").document(request.id).updateData([
            "status": "accepted",
            "driverId": driverId
        ]) { error in
            if let error = error {
                print("Error accepting ride: \(error.localizedDescription)")
            } else {
                // Update driver's availability
                db.collection("drivers").document(driverId).updateData([
                    "isAvailable": false
                ]) { error in
                    if let error = error {
                        print("Error updating availability: \(error.localizedDescription)")
                    } else {
                        print("Driver availability updated.")
                        self.isAvailable = false // Sync UI toggle
                    }
                }
            }
        }
    }

    private func updateDriverAvailability(isAvailable: Bool) {
        guard let driverId = Auth.auth().currentUser?.uid else { return }

        db.collection("drivers").document(driverId).updateData([
            "isAvailable": isAvailable
        ]) { error in
            if let error = error {
                print("Error updating availability: \(error.localizedDescription)")
            }
        }
    }
}






  
    
   
    

   
    
   

   

  








/*
import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct ManageRidesView: View {
    @State private var rideRequests: [RideRequest] = [] // New ride requests
    @State private var assignedRides: [Ride] = []       // Rides assigned to the driver
    @State private var errorMessage: String = ""
    @State private var availableRides: [RideRequest] = []
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                List {
                    Section(header: Text("New Ride Requests")) {
                        if rideRequests.isEmpty {
                            Text("No new ride requests.")
                        } else {
                            ForEach(rideRequests) { request in
                                RideRequestRow(request: request)
                                    .onTapGesture {
                                        acceptRide(request: request)
                                    }
                            }
                        }
                    }

                    Section(header: Text("Your Assigned Rides")) {
                        if assignedRides.isEmpty {
                            Text("No assigned rides.")
                        } else {
                            ForEach(assignedRides) { ride in
                                RideRow(ride: ride)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Rides")
            .onAppear(perform: fetchRides)
        }
    }

    // Fetch both new ride requests and the driver’s assigned rides
    private func fetchRides() {
        fetchRideRequests()
        fetchAssignedRides()
    }

    private func fetchRideRequests() {
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching ride requests: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.availableRides = documents.compactMap { doc -> RideRequest? in
                    let data = doc.data()
                    guard let passengerName = data["passengerName"] as? String,
                          let pickupLocation = data["pickupLocation"] as? GeoPoint,
                          let dropoffLocation = data["dropoffLocation"] as? GeoPoint,
                          let status = data["status"] as? String else {
                        print("Error: Missing or invalid fields in document \(doc.documentID)")
                        return nil
                    }

                    return RideRequest(
                        id: doc.documentID,
                        passengerName: passengerName,
                        pickupLocation: pickupLocation,
                        dropoffLocation: dropoffLocation,
                        status: status,
                        driverId: data["driverId"] as? String,
                        fareAmount: data["fareAmount"] as? Double,
                        timestamp: data["timestamp"] as? Timestamp
                    )
                }
            }
    }

    private func fetchAssignedRides() {
        guard let driverId = Auth.auth().currentUser?.uid else {
            errorMessage = "Driver not authenticated."
            return
        }

        db.collection("rides")
            .whereField("driverId", isEqualTo: driverId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Error fetching assigned rides: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents else {
                    assignedRides = []
                    return
                }

                assignedRides = documents.compactMap { doc in
                    try? doc.data(as: Ride.self)
                }
            }
    }

    // Accept a ride request
    private func acceptRide(request: RideRequest) {
        guard let driverId = Auth.auth().currentUser?.uid else {
            errorMessage = "Unable to accept ride. Driver ID missing."
            return
        }

        let requestId = request.id // No need for optional binding, `request.id` is non-optional

        db.collection("rides").document(requestId).updateData([
            "status": "accepted",
            "driverId": driverId
        ]) { error in
            if let error = error {
                errorMessage = "Error accepting ride: \(error.localizedDescription)"
            } else {
                errorMessage = "Ride accepted successfully!"
                fetchRides() // Refresh rides
            }
        }
    }
}

struct RideRequestRow: View {
    let request: RideRequest

    var body: some View {
        VStack(alignment: .leading) {
            Text("Pickup: \(request.pickupLocation.latitude), \(request.pickupLocation.longitude)")
            Text("Dropoff: \(request.dropoffLocation.latitude), \(request.dropoffLocation.longitude)")
            Text("Status: \(request.status)")
                .foregroundColor(.orange)
        }
        .padding()
    }
}

struct RideRow: View {
    let ride: Ride

    var body: some View {
        VStack(alignment: .leading) {
            Text("Pickup: \(ride.pickupLocation.latitude), \(ride.pickupLocation.longitude)")
            Text("Dropoff: \(ride.dropoffLocation.latitude), \(ride.dropoffLocation.longitude)")
            Text("Status: \(ride.status)")
                .foregroundColor(ride.status == "completed" ? .green : .blue)
        }
        .padding()
    }
}
*/


