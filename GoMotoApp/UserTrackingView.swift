//
//  UserTrackingView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/25/25.
//
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct UserTrackingView: View {
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var mapView = MKMapView()
    private let db = Firestore.firestore()
    
    var body: some View {
        MapView(userLocation: $userLocation, destination: $driverLocation, driverLocation: $driverLocation, mapView: $mapView)
            .frame(height: 300)
            .cornerRadius(10)
            .onAppear {
                startListeningForDriverUpdates()
            }
    }
    private func startListeningForDriverUpdates() {
        // Fetch ride information and listen for driver location updates
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("rides").whereField("userId", isEqualTo: userId).whereField("status", isEqualTo: "accepted").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching ride updates: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No matching ride document found.")
                return
            }
            
            let data = document.data() // Firestore document data
            if let driverLocationGeoPoint = data["driverLocation"] as? GeoPoint {
                self.driverLocation = CLLocationCoordinate2D(
                    latitude: driverLocationGeoPoint.latitude,
                    longitude: driverLocationGeoPoint.longitude
                )
            }
            
            if let userLocationGeoPoint = data["userLocation"] as? GeoPoint {
                self.userLocation = CLLocationCoordinate2D(
                    latitude: userLocationGeoPoint.latitude,
                    longitude: userLocationGeoPoint.longitude
                )
            }
        }
    }
}
 /*   private func startListeningForDriverUpdates() {
        // Fetch ride information and listen for driver location updates
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("rides").whereField("userId", isEqualTo: userId).whereField("status", isEqualTo: "accepted").addSnapshotListener { snapshot, error in
            if let document = snapshot?.documents.first, let data = document.data() {
                if let driverLocation = data["driverLocation"] as? GeoPoint {
                    self.driverLocation = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                }
                if let userLocation = data["userLocation"] as? GeoPoint {
                    self.userLocation = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
                }
            }
        }
    }*/

