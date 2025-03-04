//
//  NavigationMapView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//

import MapKit
import SwiftUI

struct NavigationMapView: View {
    let userLocation: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
        .frame(height: 250)
    }
}
