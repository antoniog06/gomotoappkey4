//
//  LiveMapView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/8/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation

struct LiveMapView: View {
    let driverId: String // Driver ID passed when initializing the view

    @StateObject private var locationManager = LocationManager.shared
    @State private var driverLocation: CLLocationCoordinate2D? = nil
    @State private var userRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [AnnotatedLocation] = []
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var destinationLocation: CLLocationCoordinate2D? = nil
    @State private var statusMessage: String = ""
    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            // Map for location selection
            Map(coordinateRegion: $userRegion, annotationItems: annotations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(location.label == "Pickup Location" ? .blue : (location.label == "Driver Location" ? .green : .red))
                            .font(.title)
                        Text(location.label)
                            .font(.caption)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(5)
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { _ in
                        userLocation = userRegion.center
                        annotations.append(AnnotatedLocation(coordinate: userRegion.center, label: "Pickup Location"))
                        print("Pickup Location Set: \(userLocation?.latitude ?? 0), \(userLocation?.longitude ?? 0)")
                    }
            )
            .frame(height: 300)
            .cornerRadius(12)
            .padding()

            // Button for scheduling the ride
            Button(action: {
                scheduleRide()
            }) {
                Text("Schedule Ride")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Status message display
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            setupLocationManager()
            fetchDriverLocation()
        }
        .navigationTitle("Live Map")
        .padding()
    }

    private func setupLocationManager() {
        locationManager.requestAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func scheduleRide() {
        guard let userLoc = userLocation else {
            statusMessage = "Pickup location is required."
            return
        }

        guard let destLoc = destinationLocation else {
            statusMessage = "Drop-off location is required."
            return
        }

        // Calculate fare, time, and distance
        let distance = calculateDistance(from: userLoc, to: destLoc)
        let estimatedTime = calculateEstimatedTime(distance: distance)
        let fareAmount = calculateEstimatedFare(distance: distance)

        print("Pickup Location: \(userLoc)")
        print("Drop-off Location: \(destLoc)")
        print("Distance: \(distance)")
        print("Estimated Time: \(estimatedTime)")
        print("Fare Amount: \(fareAmount)")

        // Save ride to Firestore
        let rideData: [String: Any] = [
            "pickupLocation": GeoPoint(latitude: userLoc.latitude, longitude: userLoc.longitude),
            "dropoffLocation": GeoPoint(latitude: destLoc.latitude, longitude: destLoc.longitude),
            "status": "requested",
            "fareAmount": fareAmount,
            "estimatedTime": estimatedTime,
            "distance": distance,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("rides").addDocument(data: rideData) { error in
            if let error = error {
                statusMessage = "Error scheduling ride: \(error.localizedDescription)"
            } else {
                statusMessage = "Ride scheduled successfully!"
            }
        }
    }

    private func fetchDriverLocation() {
        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            if let error = error {
                self.statusMessage = "Error fetching driver location: \(error.localizedDescription)"
                return
            }

            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                self.statusMessage = "Invalid driver location data."
                return
            }

            DispatchQueue.main.async {
                self.driverLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotations.append(AnnotatedLocation(coordinate: self.driverLocation!, label: "Driver Location"))
            }
        }
    }

    // Utility Functions
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) / 1000.0 // Distance in kilometers
    }

    private func calculateEstimatedTime(distance: Double) -> String {
        let speed = 50.0 // Average speed in km/h
        let timeInHours = distance / speed
        let timeInMinutes = timeInHours * 60
        return "\(Int(timeInMinutes)) mins"
    }

    private func calculateEstimatedFare(distance: Double) -> Double {
        let baseFare = 5.0 // Base fare in dollars
        let perKmRate = 2.0 // Fare per kilometer
        return baseFare + (distance * perKmRate)
    }

    struct AnnotatedLocation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let label: String
    }


    
    // MARK: - Setup Location Updates
    private func setupLocationUpdates() {
        locationManager.startUpdatingLocation()
        if let userLocation = locationManager.currentLocation {
            userRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
  
            
       
    
    // MARK: - Get Annotations
    private func getAnnotations() -> [AnnotatedLocation] {
        var annotations: [AnnotatedLocation] = []
        
        if let userLocation = locationManager.currentLocation?.coordinate {
            annotations.append(AnnotatedLocation(coordinate: userLocation, label: "Your Location"))
        }
        
        if let driverLocation = driverLocation {
            annotations.append(AnnotatedLocation(coordinate: driverLocation, label: "Driver Location"))
        }
        
        return annotations
    }
    
    
    
    
    
    
    // MARK: - RoutePolylineOverlay
    struct RoutePolylineOverlay: UIViewRepresentable {
        let polyline: MKPolyline
        
        func makeUIView(context: Context) -> MKMapView {
            let mapView = MKMapView()
            mapView.delegate = context.coordinator
            return mapView
        }
        
        func updateUIView(_ uiView: MKMapView, context: Context) {
            uiView.removeOverlays(uiView.overlays)
            uiView.addOverlay(polyline)
            uiView.setVisibleMapRect(polyline.boundingMapRect, animated: true)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
        class Coordinator: NSObject, MKMapViewDelegate {
            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                if let polyline = overlay as? MKPolyline {
                    let renderer = MKPolylineRenderer(overlay: polyline)
                    renderer.strokeColor = .blue
                    renderer.lineWidth = 4
                    return renderer
                }
                return MKOverlayRenderer()
            }
        }
    }
}
