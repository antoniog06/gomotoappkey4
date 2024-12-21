//
//  LiveMapView.swift
//  GoMoto
//
//  Created by AnthonyG

import SwiftUI
import MapKit

struct LiveMapView: View {
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Example coordinates for San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $coordinateRegion, showsUserLocation: true)
            .ignoresSafeArea(edges: .all)
    }
}
