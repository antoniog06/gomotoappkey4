//
//  RideItemView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/14/25.
//
import CoreLocation
import SDWebImageSwiftUI
import Firebase
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import MapKit

struct RideItemView: View {
    let ride: RideRequest
    let onAccept: (RideRequest) -> Void
    let onDecline: (RideRequest) -> Void

    @State private var pickupAddress: String = "Loading..."
    @State private var dropoffAddress: String = "Loading..."
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let pickupGeoPoint = ride.pickupLocation as? GeoPoint,
               let dropoffGeoPoint = ride.dropoffLocation as? GeoPoint {

                let pickupCoordinate = CLLocationCoordinate2D(
                    latitude: pickupGeoPoint.latitude,
                    longitude: pickupGeoPoint.longitude
                )
                let dropoffCoordinate = CLLocationCoordinate2D(
                    latitude: dropoffGeoPoint.latitude,
                    longitude: dropoffGeoPoint.longitude
                )

                let distance = calculateDistance(from: pickupCoordinate, to: dropoffCoordinate)
                let fareAmount = calculateFare(distance: distance)

                Text("📍 Pickup: \(pickupAddress)")
                Text("📍 Dropoff: \(dropoffAddress)")
                Text("📏 Distance: \(String(format: "%.1f", distance)) miles")
                Text("💰 Fare: $\(String(format: "%.2f", fareAmount))")

                HStack {
                    Button("✅ Accept") {
                        onAccept(ride)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.8)).shadow(radius: 5))

                    Button("❌ Decline") {
                        onDecline(ride)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.8)).shadow(radius: 5))
                }
            } else {
                Text("⚠️ Location data unavailable")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)).shadow(radius: 5))
        .onAppear {
            fetchAddresses()
        }
    }

    // ✅ Move Reverse Geocoding Here
    private func fetchAddresses() {
        if let pickupGeoPoint = ride.pickupLocation as? GeoPoint,
           let dropoffGeoPoint = ride.dropoffLocation as? GeoPoint {

            let pickupCoordinate = CLLocationCoordinate2D(
                latitude: pickupGeoPoint.latitude,
                longitude: pickupGeoPoint.longitude
            )
            let dropoffCoordinate = CLLocationCoordinate2D(
                latitude: dropoffGeoPoint.latitude,
                longitude: dropoffGeoPoint.longitude
            )

            reverseGeocodeLocation(pickupCoordinate) { address in
                DispatchQueue.main.async {
                    self.pickupAddress = address
                }
            }

            reverseGeocodeLocation(dropoffCoordinate) { address in
                DispatchQueue.main.async {
                    self.dropoffAddress = address
                }
            }
        }
    }

    private func calculateFare(distance: Double) -> Double {
        let baseFare = 5.0
        let perMileRate = 2.0
        let totalFare = (baseFare + (distance * perMileRate)) * surgePricing * baseRateMultiplier
        return totalFare
    }
    
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        
        let distanceInMeters = startLocation.distance(from: endLocation) // Get distance in meters
        let distanceInMiles = distanceInMeters / 1609.34 // Convert to miles
        
        return distanceInMiles
    }
   

    // MARK: - Reverse Geocode Function
    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Reverse Geocode Error: \(error.localizedDescription)")
                completion("Unknown") // Return "Unknown" if there's an error
                return
            }

            if let placemark = placemarks?.first {
                let address = [
                    placemark.subThoroughfare ?? "",  // House number
                    placemark.thoroughfare ?? "",      // Street name
                    placemark.locality ?? "",          // City
                    placemark.administrativeArea ?? "", // State
                    placemark.country ?? ""            // Country
                ].joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)

                completion(address.isEmpty ? "Unknown" : address)
            } else {
                completion("Unknown")
            }
        }
    }
   
}
