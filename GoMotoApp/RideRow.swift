//
//  RideRow.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/24/25.
//


import SwiftUI
import MapKit
import FirebaseFirestore

struct RideRow: View {
    let ride: Ride
    @State private var pickupAddress: String = "Loading..."
    @State private var dropoffAddress: String = "Loading..."

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pickup: \(pickupAddress)")
            Text("Dropoff: \(dropoffAddress)")
            Text("Status: \(ride.status)")
                .foregroundColor(ride.status == "completed" ? .green : .blue)
        }
        .padding()
        .onAppear {
            reverseGeocode(location: ride.pickupLocation) { address in
                pickupAddress = address
            }
            reverseGeocode(location: ride.dropoffLocation) { address in
                dropoffAddress = address
            }
        }
    }

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
}

