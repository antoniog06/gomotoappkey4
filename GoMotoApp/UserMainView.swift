//
//  UserMainView.swift
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

struct UserMainView: View {
    @Binding var isLoggedIn: Bool
    var body: some View {
        TabView {
            UserDashboardView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RideHistoryView()
                .tabItem {
                    Label("My Rides", systemImage: "clock.fill")
                }

            PaymentView()
                .tabItem {
                    Label("Payments", systemImage: "creditcard.fill")
                }

            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
