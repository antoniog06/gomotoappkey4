//
//  DriverMainView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct DriverMainView: View {
    @Binding var isLoggedIn: Bool
    var driverId: String
    
    var body: some View {
        TabView {
            DriverDashboardView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            RideHistoryView()
                .tabItem {
                    Label("Ride History", systemImage: "clock.fill")
                }

            PaymentView()
                .tabItem {
                    Label("Earnings", systemImage: "dollarsign.circle.fill")
                }

            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
