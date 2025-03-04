//
//  RideRequestRow.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/24/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct RideRequestRow: View {
    let request: RideRequest
    private let db = Firestore.firestore()
    @State private var pickupAddress: String = "Loading..."
    @State private var dropoffAddress: String = "Loading..."
    @State private var statusMessage: String = ""
    @State private var mapView = MKMapView()
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var destination: CLLocationCoordinate2D? = nil
    @State private var driverLocation: CLLocationCoordinate2D? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pickup: \(pickupAddress)").font(.subheadline)
            Text("Dropoff: \(dropoffAddress)").font(.subheadline)
            Text("Fare: $\(request.fareAmount ?? 0.0, specifier: "%.2f")").foregroundColor(.green)
            
            MapView(userLocation: $userLocation, destination: $destination, driverLocation: $driverLocation, mapView: $mapView)
                .frame(height: 200)
                .cornerRadius(10)
            
            HStack {
                Button("Accept") {
                    acceptRide()
                    if let driverLoc = driverLocation {
                        drawRoute(from: driverLoc, to: CLLocationCoordinate2D(latitude: request.pickupLocation.latitude, longitude: request.pickupLocation.longitude), mapView: mapView)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Decline") {
                    declineRide()
                }
                .buttonStyle(.bordered)
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage).foregroundColor(.blue).font(.caption)
            }
        }
        .padding()
        .onAppear {
            reverseGeocode(location: request.pickupLocation) { address in
                pickupAddress = address
            }
            reverseGeocode(location: request.dropoffLocation) { address in
                dropoffAddress = address
            }
            driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // Example location
        }
    }

    private func drawRoute(from driverLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, mapView: MKMapView) {
        let sourcePlacemark = MKPlacemark(coordinate: driverLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                print("Error calculating route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
    
    private func reverseGeocode(location: GeoPoint, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(loc) { placemarks, error in
            if let placemark = placemarks?.first, let address = placemark.compactAddress {
                completion(address)
            } else {
                completion("Unknown Address")
            }
        }
    }

    private func acceptRide() {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        db.collection("rides").document(request.id).updateData([
            "status": "accepted",
            "driverId": driverId
        ]) { error in
            if let error = error {
                print("Error accepting ride: \(error.localizedDescription)")
                statusMessage = "Error accepting ride."
            } else {
                statusMessage = "You accepted the ride."
            }
        }
    }

    private func declineRide() {
        db.collection("rides").document(request.id).updateData(["status": "declined"]) { error in
            if let error = error {
                statusMessage = "Error declining ride."
            } else {
                statusMessage = "You declined the ride."
            }
        }
    }
}

extension CLPlacemark {
    var compactAddress: String? {
        if let name = name, let city = locality {
            return "\(name), \(city)"
        } else {
            return nil
        }
    }
}


/*
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import MapKit

struct RideRequestRow: View {
    let request: RideRequest
    private let db = Firestore.firestore()
    @State private var pickupAddress: String = "Loading..."
    @State private var dropoffAddress: String = "Loading..."
    @State private var statusMessage: String = ""
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var destination: CLLocationCoordinate2D? = nil
    @State private var driverLocation: CLLocationCoordinate2D? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display Pickup and Dropoff Address
            Text("Pickup: \(pickupAddress)")
                .font(.subheadline)
            Text("Dropoff: \(dropoffAddress)")
                .font(.subheadline)
            Text("Fare: $\(request.fareAmount ?? 0.0, specifier: "%.2f")")
                .foregroundColor(.green)
            
            // Map View
            MapView(userLocation: $userLocation, destination: $destination, driverLocation: $driverLocation, mapView: $mapView)
                .frame(height: 200)
                .cornerRadius(10)
            
            // Action Buttons
            HStack {
                Button("Accept") {
                    acceptRide()
                    if let driverLoc = driverLocation {
                        drawRoute(from: driverLoc, to: CLLocationCoordinate2D(latitude: request.pickupLocation.latitude, longitude: request.pickupLocation.longitude))
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Decline") {
                    declineRide()
                }
                .buttonStyle(.bordered)
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding()
        .onAppear {
            // Reverse Geocode Locations
            reverseGeocode(location: request.pickupLocation) { address in
                pickupAddress = address
            }
            reverseGeocode(location: request.dropoffLocation) { address in
                dropoffAddress = address
            }
            
            // Simulate or Fetch Driver Location
            driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // Mocked Location
            destination = CLLocationCoordinate2D(latitude: request.dropoffLocation.latitude, longitude: request.dropoffLocation.longitude)
        }
    }
    
    // MARK: - Accept Ride
    private func acceptRide() {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("rides").document(request.id).updateData([
            "status": "accepted",
            "driverId": driverId
        ]) { error in
            if let error = error {
                print("Error accepting ride: \(error.localizedDescription)")
                statusMessage = "Error accepting ride."
            } else {
                print("Ride accepted.")
                statusMessage = "You accepted the ride."
                
                // Update Driver's Availability
                db.collection("drivers").document(driverId).updateData([
                    "isAvailable": false
                ]) { error in
                    if let error = error {
                        print("Error updating availability: \(error.localizedDescription)")
                    } else {
                        print("Driver availability updated.")
                    }
                }
            }
        }
    }
    
    // MARK: - Decline Ride
    private func declineRide() {
        db.collection("rides").document(request.id).updateData([
            "status": "declined"
        ]) { error in
            if let error = error {
                print("Error declining ride: \(error.localizedDescription)")
                statusMessage = "Error declining ride."
            } else {
                print("Ride declined.")
                statusMessage = "You declined the ride."
            }
        }
    }
    
    
    
    // MARK: - Draw Route
    private func drawRoute(from driverLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: driverLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                print("Error calculating route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }

// MARK: - Overlay Renderer
func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? MKPolyline {
        let renderer = MKPolylineRenderer(overlay: polyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 4.0
        return renderer
    }
    return MKOverlayRenderer(overlay: overlay)
}
}
    
    // MARK: - Reverse Geocode
    // MARK: - Reverse Geocode
    private func reverseGeocode(location: GeoPoint, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first, let address = placemark.compactAddress {
                completion(address)
            } else {
                completion("Unknown Address")
            }
        }
    }
    
    extension CLPlacemark {
        var compactAddress: String? {
            var components: [String] = []
            if let name = name { components.append(name) }
            if let locality = locality { components.append(locality) }
            if let administrativeArea = administrativeArea { components.append(administrativeArea) }
            if let country = country { components.append(country) }
            return components.joined(separator: ", ")
        }
    }
    */
    
    
    

