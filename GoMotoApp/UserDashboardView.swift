//
//  UserDashboardView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct UserDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var activeRide: RideRequest? // Active ride
    @State private var mapView = MKMapView()
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var driverLocation: CLLocationCoordinate2D?
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let ride = activeRide {
                    VStack(spacing: 10) {
                        Text("Your Ride").font(.headline)
                        
                        // Reusable MapView
                        ReusableMapView(
                            driverLocation: $driverLocation,
                            pickupLocation: CLLocationCoordinate2D(
                                latitude: ride.pickupLocation.latitude,
                                longitude: ride.pickupLocation.longitude
                            ),
                            dropoffLocation: CLLocationCoordinate2D(
                                latitude: ride.dropoffLocation.latitude,
                                longitude: ride.dropoffLocation.longitude
                            ),
                            mapView: mapView // ✅ Use `mapView` instead of `$mapView`
                        )
                        .frame(height: 300)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                            Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                        }

                        Button("Track Driver") {
                            trackDriverLocation(ride: ride)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("No active rides.")
                            .foregroundColor(.gray)

                        // Request Ride Button
                        NavigationLink(destination: RideSchedulingView()) {
                            Text("Request a Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .onAppear {
                fetchUserLocation()
                fetchActiveRide()
            }
            .navigationTitle("User Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: logout) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // 🔹 Logout Function
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false // ✅ Updates binding to navigate back to WelcomeView
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    private func fetchUserLocation() {
        if let location = LocationManager.shared.userLocation {
            self.userLocation = location
        } else {
            print("Failed to get user location.")
        }
    }

    private func fetchActiveRide() {
        db.collection("rides")
            .whereField("userId", isEqualTo: "mockUserId") // Replace with actual user ID
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching active ride: \(error.localizedDescription)")
                    return
                }
                guard let document = snapshot?.documents.first else {
                    print("No active rides found.")
                    return
                }
                self.activeRide = RideRequest(
                    id: document.documentID,
                    data: document.data()
                )
            }
    }

    private func trackDriverLocation(ride: RideRequest) {
        guard let driverId = ride.driverId else {
            print("Driver ID is missing.")
            return
        }

        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error tracking driver: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                print("Failed to fetch driver location.")
                return
            }
            self.driverLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

/*import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct UserDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var activeRide: RideRequest?
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var profileImageURL: String?
    @State private var rideHistory: [RideRequest] = []
    @ObservedObject private var locationManager = RealTimeLocationManager.shared
    @State private var showEarningsBreakdown: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // **Animated Background**
            PulsatingGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                userStatusHeader
                    .modifier(FloatingCardEffect())

                Group {
                    if let ride = activeRide {
                        activeRideView(ride: ride)
                            .transition(.asymmetric(
                                insertion: .skewedSlide(.trailing),
                                removal: .skewedSlide(.leading)
                            ))
                    } else {
                        requestRideButton
                    }
                }
                .animation(.spring(), value: activeRide)
                
                rideHistorySection
                    .modifier(ChartElevationEffect())

                Spacer()

                actionPanel
                    .modifier(ButtonStackEffect())
            }
            .padding(.horizontal)
        }
        .overlay(loadingOverlay)
        .alert(errorMessage: $errorMessage)
        .onAppear(perform: initializeDashboard)
        .onReceive(locationManager.$userLocation) { location in
            handleLocationUpdate(location)
        }
    }
}

// MARK: - Core Functionality
extension UserDashboardView {
    private func initializeDashboard() {
        setupFirestoreListeners()
        fetchUserProfile()
        setupPerformanceMonitoring()
    }

    private func setupFirestoreListeners() {
        // **Listen for Active Ride Updates**
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("rides")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", in: ["accepted", "on_the_way", "in_progress"])
            .addSnapshotListener { snapshot, _ in
                self.activeRide = snapshot?.documents.compactMap { RideRequest(doc: $0) }.first
            }
        
        // **Listen for Ride History**
        db.collection("rides")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { snapshot, _ in
                self.rideHistory = snapshot?.documents.map { RideRequest(doc: $0) } ?? []
            }
    }
}

// MARK: - Advanced UI Components
extension UserDashboardView {
    private var userStatusHeader: some View {
        HStack(spacing: 16) {
            UserProfileView(imageUrl: profileImageURL)
                .animation(.bouncy, value: profileImageURL)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("GoMoto Passenger")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        .transition(.textFade)
                    
                    OnlineStatusIndicator(isOnline: true)
                }
                
                RidePerformanceMeter(metrics: rideHistory.count)
                    .animation(.ripple(), value: rideHistory.count)
            }
            
            Spacer()
        }
        .padding()
        .background(VisualEffectView(.systemUltraThinMaterial))
        .cornerRadius(20)
        .modifier(NeumorphicShadow())
    }
    
    private var requestRideButton: some View {
        Button(action: requestRide) {
            HStack {
                Image(systemName: "car.fill")
                Text("Request a Ride")
                    .bold()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.gradient)
            .foregroundColor(.white)
            .cornerRadius(12)
            .modifier(BouncyButtonStyle())
        }
    }
    
    private func activeRideView(ride: RideRequest) -> some View {
        VStack(spacing: 16) {
            NavigationMapView(
                userLocation: $locationManager.userLocation,
                destination: ride.dropoffLocation.coordinate,
                routeType: .fastest
            )
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RideNavigationOverlay(ride: ride)
                    .transition(.overlayFade)
            )
            .modifier(MapPulseEffect())
            
            RideControlPanel(
                ride: ride,
                onComplete: completeRide,
                onEmergency: triggerEmergencyProtocol
            )
            .transition(.buttonCluster)
        }
    }
    
    private var rideHistorySection: some View {
        VStack {
            Text("Ride History")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView {
                LazyVStack {
                    ForEach(rideHistory, id: \.id) { ride in
                        RideHistoryCard(ride: ride)
                            .transition(.cardInsertion)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .shadow(radius: 5)
        )
    }
    
    private var actionPanel: some View {
        HStack(spacing: 16) {
            NavigationLink {
                UserInboxView()
            } label: {
                Image(systemName: "bell.badge")
                    .symbolEffect(.bounce, options: .repeating, value: rideHistory.count)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
            .buttonStyle(.bouncy)
            
            Button(action: logout) {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .modifier(BouncyButtonStyle())
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Business Logic
extension UserDashboardView {
    private func requestRide() {
        guard let userId = auth.currentUser?.uid else { return }

        let newRide = RideRequest(
            id: UUID().uuidString,
            userId: userId,
            pickupLocation: locationManager.userLocation,
            dropoffLocation: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Example location
            status: "requested"
        )
        
        db.collection("rides").document(newRide.id).setData(newRide.toDictionary()) { error in
            if let error = error {
                errorMessage = "Error requesting ride: \(error.localizedDescription)"
            }
        }
    }
    
    private func completeRide() {
        guard let ride = activeRide else { return }
        
        db.collection("rides").document(ride.id).updateData([
            "status": "completed"
        ])
        
        withAnimation {
            activeRide = nil
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        db.collection("users").document(auth.currentUser?.uid ?? "")
            .updateData([
                "location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                "lastUpdated": FieldValue.serverTimestamp()
            ])
    }
    
    private func triggerEmergencyProtocol() {
        EmergencySystem.shared.triggerEmergency(
            location: locationManager.userLocation,
            rideDetails: activeRide
        )
    }
    
    private func logout() {
        do {
            try auth.signOut()
            isLoggedIn = false
        } catch {
            errorMessage = "Logout failed: \(error.localizedDescription)"
        }
    }
}*/


/*import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct UserDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var activeRide: RideRequest? // Active ride
    @State private var mapView = MKMapView()
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var driverLocation: CLLocationCoordinate2D?
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let ride = activeRide {
                    VStack(spacing: 10) {
                        Text("Your Ride").font(.headline)
                        
                        // Reusable MapView
                        ReusableMapView(
                            driverLocation: $driverLocation,
                            pickupLocation: CLLocationCoordinate2D(
                                latitude: ride.pickupLocation.latitude,
                                longitude: ride.pickupLocation.longitude
                            ),
                            dropoffLocation: CLLocationCoordinate2D(
                                latitude: ride.dropoffLocation.latitude,
                                longitude: ride.dropoffLocation.longitude
                            ),
                            mapView: mapView // ✅ Use `mapView` instead of `$mapView`
                        )
                        .frame(height: 300)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                            Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                        }

                        Button("Track Driver") {
                            trackDriverLocation(ride: ride)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("No active rides.")
                            .foregroundColor(.gray)

                        // Request Ride Button
                        NavigationLink(destination: RideSchedulingView()) {
                            Text("Request a Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .onAppear {
                fetchUserLocation()
                fetchActiveRide()
            }
            .navigationTitle("User Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: logout) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // 🔹 Logout Function
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false // ✅ Updates binding to navigate back to WelcomeView
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    private func fetchUserLocation() {
        if let location = LocationManager.shared.userLocation {
            self.userLocation = location
        } else {
            print("Failed to get user location.")
        }
    }

    private func fetchActiveRide() {
        db.collection("rides")
            .whereField("userId", isEqualTo: "mockUserId") // Replace with actual user ID
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching active ride: \(error.localizedDescription)")
                    return
                }
                guard let document = snapshot?.documents.first else {
                    print("No active rides found.")
                    return
                }
                self.activeRide = RideRequest(
                    id: document.documentID,
                    data: document.data()
                )
            }
    }

    private func trackDriverLocation(ride: RideRequest) {
        guard let driverId = ride.driverId else {
            print("Driver ID is missing.")
            return
        }

        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error tracking driver: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                print("Failed to fetch driver location.")
                return
            }
            self.driverLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}*/

/*
import SwiftUI
import FirebaseFirestore
import MapKit

struct UserDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var activeRide: RideRequest? // Active ride
    @State private var mapView = MKMapView()
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var driverLocation: CLLocationCoordinate2D?
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let ride = activeRide {
                    VStack(spacing: 10) {
                        Text("Your Ride").font(.headline)
                        
                        // Reusable MapView
                        ReusableMapView(
                            driverLocation: $driverLocation,
                            pickupLocation: CLLocationCoordinate2D(
                                latitude: ride.pickupLocation.latitude,
                                longitude: ride.pickupLocation.longitude
                            ),
                            dropoffLocation: CLLocationCoordinate2D(
                                latitude: ride.dropoffLocation.latitude,
                                longitude: ride.dropoffLocation.longitude
                            ),
                            mapView: mapView // ✅ Use `mapView` instead of `$mapView`
                        )
                        .frame(height: 300)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                            Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                        }

                        Button("Track Driver") {
                            trackDriverLocation(ride: ride)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("No active rides.")
                            .foregroundColor(.gray)

                        // Request Ride Button
                        NavigationLink(destination: RideSchedulingView()) {
                            Text("Request a Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .onAppear {
                fetchUserLocation()
                fetchActiveRide()
            }
            .navigationTitle("User Dashboard")
        }
    }

    private func fetchUserLocation() {
        if let location = LocationManager.shared.userLocation {
            self.userLocation = location
        } else {
            print("Failed to get user location.")
        }
    }

    private func fetchActiveRide() {
        db.collection("rides")
            .whereField("userId", isEqualTo: "mockUserId") // Replace with actual user ID
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching active ride: \(error.localizedDescription)")
                    return
                }
                guard let document = snapshot?.documents.first else {
                    print("No active rides found.")
                    return
                }
                self.activeRide = RideRequest(
                    id: document.documentID,
                    data: document.data()
                )
            }
    }

    private func trackDriverLocation(ride: RideRequest) {
        guard let driverId = ride.driverId else {
            print("Driver ID is missing.")
            return
        }

        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error tracking driver: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                print("Failed to fetch driver location.")
                return
            }
            self.driverLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}*/

/*
import SwiftUI
import FirebaseFirestore
import MapKit

struct UserDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var activeRide: RideRequest? // Active ride
    @State private var mapView = MKMapView()
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var driverLocation: CLLocationCoordinate2D?
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let ride = activeRide {
                    VStack(spacing: 10) {
                        Text("Your Ride").font(.headline)
                        
                        // New ReusableMapView
                        ReusableMapView(
                            driverLocation: $driverLocation,
                            pickupLocation: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                            dropoffLocation: CLLocationCoordinate2D(latitude: 40.73061, longitude: -73.935242),
                            mapView: MKMapView()
                        )
                        .frame(height: 300)

                        // MapViewWithRoutes: Displays user's current location, pickup, and dropoff
                        MapViewWithRoutes(
                            driverLocation: Binding(
                                get: { userLocation },
                                set: { userLocation = $0 }
                            ),
                            pickupLocation: CLLocationCoordinate2D(
                                latitude: ride.pickupLocation.latitude,
                                longitude: ride.pickupLocation.longitude
                            ),
                            dropoffLocation: CLLocationCoordinate2D(
                                latitude: ride.dropoffLocation.latitude,
                                longitude: ride.dropoffLocation.longitude
                            ),
                            mapView: $mapView
                        )
                        .frame(height: 300)
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                            Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                        }

                        Button("Track Driver") {
                            trackDriverLocation(ride: ride)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("No active rides.")
                            .foregroundColor(.gray)

                        // Request Ride Button
                        NavigationLink(destination: RideSchedulingView()) {
                            Text("Request a Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .onAppear {
                fetchUserLocation()
                fetchActiveRide()
            }
            .navigationTitle("User Dashboard")
        }
    }

    private func fetchUserLocation() {
        if let location = LocationManager.shared.userLocation {
            self.userLocation = location
        } else {
            print("Failed to get user location.")
        }
    }

    private func fetchActiveRide() {
        // Fetch active ride for the user
        db.collection("rides")
            .whereField("userId", isEqualTo: "mockUserId") // Replace with actual user ID
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching active ride: \(error.localizedDescription)")
                    return
                }
                guard let document = snapshot?.documents.first else {
                    print("No active rides found.")
                    return
                }
                self.activeRide = RideRequest(
                    id: document.documentID,
                    data: document.data()
                )
            }
    }

    private func trackDriverLocation(ride: RideRequest) {
        // Unwrap the optional driverId
        guard let driverId = ride.driverId else {
            print("Driver ID is missing.")
            return
        }

        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error tracking driver: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data(),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double else {
                print("Failed to fetch driver location.")
                return
            }
            let driverLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            updateMapWithDriverLocation(driverLocation)
        }
    }
    private func updateMapWithDriverLocation(_ location: CLLocationCoordinate2D) {
        // Update the map view with the driver's new location
        mapView.setCenter(location, animated: true)
    }
}*/
//
/*
import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Welcome to Your Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                Spacer()

                // Request a Ride
                NavigationLink(destination: RideSchedulingView()) {
                    dashboardButton(text: "Request a Ride", color: .blue)
                }

                // Ride History
                NavigationLink(destination: RideHistoryView()) {
                    dashboardButton(text: "Ride History", color: .orange)
                }

                // Track Ride
                NavigationLink(destination: LiveMapView(driverId: "exampleDriverId")) {
                    dashboardButton(text: "Track Ride", color: .green)
                }

                // Profile
                NavigationLink(destination: ProfileView()) {
                    dashboardButton(text: "Profile", color: .gray)
                }

                // Settings
                NavigationLink(destination: SettingsView()) {
                    dashboardButton(text: "Settings", color: .purple)
                }

                Spacer()

                // Logout Button
                Button(action: logout) {
                    dashboardButton(text: "Logout", color: .red)
                }
                .padding(.top, 30)
            }
            .padding()
            .navigationTitle("User Dashboard")
        }
    }

    // MARK: - Reusable Button
    private func dashboardButton(text: String, color: Color) -> some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
    }

    // MARK: - Logout Function
    private func logout() {
        authManager.logout { result in
            switch result {
            case .success:
                isLoggedIn = false // Redirect back to WelcomeView
            case .failure(let error):
                print("Logout failed: \(error.localizedDescription)")
            }
        }
    }
}
*/
