//
//  DriverDashboardView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.



import CoreLocation
import SDWebImageSwiftUI
import Firebase
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import MapKit

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest?
    @State private var mapView = MKMapView()
    @State private var isOffline: Bool = false
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showProfileView: Bool = false
    @State private var showAnsweringView = false
    @State private var showRideHistoryView: Bool = false
    @State private var surgePricing: Double = 1.0
    @State private var baseRateMultiplier: Double = 1.0
    @State private var pickupAddress: String = "Fetching..."
    @State private var dropoffAddress: String = "Fetching..."
    @State private var driverEarnings: Double = 0.0
    
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let geocoder = CLGeocoder() // Geocoder Instance
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // **🔹 Glowing Background**
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // **🔹 Header with Glow Effect**
                    Text("🚖 Driver Dashboard")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.8), radius: 5)
                    
                    if let ride = activeRide {
                        activeRideView(ride: ride)
                    } else if availableRides.isEmpty && !isLoading {
                        noAvailableRidesView
                    } else {
                        availableRidesListView
                    }
                    
                    Spacer()
                    
                    // **🔹 Profile, Ride History & View Ride Details (As in First Picture)**
                    actionButtons
                    //answering view button
                    answeringViewButton
                    List {
                        NavigationLink(destination: PaymentView()) {
                            Text("💳 Payments")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                }
                .padding()
                .onAppear {
                    fetchDriverLocation()
                    fetchAvailableRides()
                    fetchDriverEarnings()
                }
                .overlay(
                    isLoading ? ProgressView().scaleEffect(2) : nil
                )
                .alert(isPresented: .constant(errorMessage != nil), content: {
                    Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
                })
            }
            // fix ride history view
            .sheet(isPresented: $showRideHistoryView) {
                RideHistoryView()
            }
            // fix Profilr View
            .fullScreenCover(isPresented: $showProfileView) {
                ProfileView(isLoggedIn: $isLoggedIn)
                
            }
            .navigationTitle("Driver Dashboard")
        }
    }
}
// MARK: - 🚗 No Available Rides

extension DriverDashboardView {
    private var noAvailableRidesView: some View {
        Text("No available rides.")
            .foregroundColor(.gray)
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)))
    }
    
    private var availableRidesListView: some View {
        List(availableRides) { ride in
            RideItemView(ride: ride, onAccept: acceptRide, onDecline: declineRide)
        }
    }
  
// MARK: - 🚗 Active Ride View
private func activeRideView(ride: RideRequest) -> some View {
    VStack(spacing: 10) {
        Text("🚖 Active Ride")
            .font(.title2)
            .bold()
            .foregroundColor(.white)
        
        if let pickupGeoPoint = ride.pickupLocation as? GeoPoint,
           let dropoffGeoPoint = ride.dropoffLocation as? GeoPoint,
           let driverLoc = driverLocation {
            
            let pickupCoordinate = CLLocationCoordinate2D(
                latitude: pickupGeoPoint.latitude,
                longitude: pickupGeoPoint.longitude
            )
            let dropoffCoordinate = CLLocationCoordinate2D(
                latitude: dropoffGeoPoint.latitude,
                longitude: dropoffGeoPoint.longitude
            )
            
            // **Calculate Distance**
            let distance = calculateDistance(from: pickupCoordinate, to: dropoffCoordinate)
            let fareAmount = calculateFare(distance: distance)
            
            // **🔹 Display MapView**
            MapView(
                userLocation: Binding.constant(pickupCoordinate),
                destination: Binding.constant(dropoffCoordinate),
                driverLocation: Binding.constant(driverLoc),
                mapView: $mapView
            )
            .frame(height: 300)
            .cornerRadius(15)
            .shadow(radius: 10)
            
            // **🔹 Ride Information**
            VStack(alignment: .leading, spacing: 8) {
                Text("📍 Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("📍 Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                Text("📏 Distance: \(String(format: "%.1f", distance)) miles")
                Text("💰 Fare: $\(String(format: "%.2f", fareAmount))")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)).shadow(radius: 5))
            
            // **🔹 Start Navigation & Complete Ride Buttons**
            HStack {
                Button(action: {
                    startNavigation(driverLocation: driverLoc, pickupLocation: pickupCoordinate, dropoffLocation: dropoffCoordinate)
                }) {
                    Text("🚀 Start Navigation")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                Button(action: {
                    completeRide(ride: ride)
                }) {
                    Text("✅ Complete Ride")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        } else {
            Text("⚠️ Location data unavailable")
                .foregroundColor(.red)
        }
    }
    .padding()
}
}


// MARK: - 🚀 Profile & Ride History Buttons (As in First Picture)
extension DriverDashboardView {
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // profil
            Button(action:  {
                showProfileView = true
            }) {
                Text("👤 Profile")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showProfileView) {
                ProfileView(isLoggedIn: $isLoggedIn)
            }
            Button(action: {
                showRideHistoryView = true
            }) {
                Text("📜 Ride History")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showRideHistoryView) {
                RideHistoryView()
            }
        }
    }
}

// MARK: - 🚗 Navigate to AnsweringView (As in First Picture)
extension DriverDashboardView {
    private var answeringViewButton: some View {
        Button(action:  {
            showAnsweringView = true
        }) {
            Text("🔍 View Ride Details")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .sheet(isPresented: $showAnsweringView) {
            AnsweringView(isLoggedIn: $isLoggedIn, driverId: "your Driver Id Here")
        }
    }
}
    // MARK: - Functions
extension DriverDashboardView {
    private func fetchDriverLocation() {
        // Mock driver location (replace with actual location updates from a LocationManager)
        driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }
    
    func createStripeAccount(for driverId: String) {
        let stripeAccountId = UUID().uuidString // Generate a unique ID (replace with Stripe API call)
        
        db.collection("drivers").document(driverId).setData([
            "stripeAccountId": stripeAccountId
        ], merge: true)
    }
    
    private func fetchAvailableRides() {
        isLoading = true
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(
                        id: doc.documentID,
                        data: doc.data()
                    )
                }
            }
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
    
    private func completeRide(ride: RideRequest) {
        guard let driverId = Auth.auth().currentUser?.uid else {
            print("Error: No driver ID found")
            return
        }

        let fare = ride.fareAmount ?? 0.0
        let driverRef = Firestore.firestore().collection("drivers").document(driverId)

        Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
            let driverDoc: DocumentSnapshot
            do {
                driverDoc = try transaction.getDocument(driverRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            // Get current values or set default
            let currentEarnings = driverDoc.data()?["earnings"] as? Double ?? 0.0
            let currentRides = driverDoc.data()?["completedRides"] as? Int ?? 0

            // Update values
            let updatedEarnings = currentEarnings + fare
            let updatedRides = currentRides + 1

            // Update Firestore document
            transaction.updateData([
                "earnings": updatedEarnings,
                "completedRides": updatedRides
            ], forDocument: driverRef)

            return nil
        } completion: { (_, error) in
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                print("Earnings and completed rides updated successfully!")
            }
        }

        // Reset active ride and refresh available rides
        activeRide = nil
        fetchAvailableRides()
    }

    private func fetchDriverEarnings() {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        
        let driverRef = db.collection("drivers").document(driverId)
        driverRef.addSnapshotListener { document, error in
            if let document = document, document.exists {
                self.driverEarnings = document.data()?["earnings"] as? Double ?? 0.0
            }
        }
    }
    private func acceptRide(ride: RideRequest) {
        guard let driverId = Auth.auth().currentUser?.uid else { return }

        let rideRef = db.collection("rides").document(ride.id)
        rideRef.updateData([
            "status": "accepted",
            "driverId": driverId,
            "fareAmount": ride.fareAmount ?? 0.0
        ]) { error in
            if let error = error {
                print("Error accepting ride: \(error.localizedDescription)")
            } else {
                self.activeRide = ride
            }
        }
    }
  /*  private func acceptRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "accepted",
            "driverId": "mockDriverId" // Replace with the actual driver ID
        ]) { error in
            if let error = error {
                errorMessage = "Error accepting ride: \(error.localizedDescription)"
                return
            }
            activeRide = ride
        }
    }*/
    
    private func declineRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "declined"
        ]) { error in
            if let error = error {
                errorMessage = "Error declining ride: \(error.localizedDescription)"
                return
            }
            availableRides.removeAll { $0.id == ride.id }
        }
    }
    
    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }
    private func startNavigation(driverLocation: CLLocationCoordinate2D, pickupLocation: CLLocationCoordinate2D, dropoffLocation: CLLocationCoordinate2D) {
        let driverPlacemark = MKPlacemark(coordinate: driverLocation)
        let pickupPlacemark = MKPlacemark(coordinate: pickupLocation)
        let dropoffPlacemark = MKPlacemark(coordinate: dropoffLocation)
        
        let driverMapItem = MKMapItem(placemark: driverPlacemark)
        driverMapItem.name = "Driver Location"
        
        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
        pickupMapItem.name = "Pickup Location"
        
        let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
        dropoffMapItem.name = "Dropoff Location"
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ]
        
        // Open Apple Maps with all three locations
        MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }
    // MARK: - Subviews
   
}
// MARK: - 🚀 Fare Calculation
extension DriverDashboardView {
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



    enum LocationType {
        case pickup
        case dropoff
    }
}

    
   
    

        
        
    

/*
 import SDWebImageSwiftUI
 import Firebase
 import FirebaseAuth
 import SwiftUI
 import FirebaseFirestore
 import MapKit

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest? // Currently accepted ride
    @State private var mapView = MKMapView()
    @State private var isOffline: Bool = false // Track online/offline status
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showProfileView: Bool = false
    private let locationManager = CLLocationManager()
    @State private var showRideHistoryView: Bool = false
    @State private var showAnsweringView = false
    private let auth = Auth.auth()
    
    private let db = Firestore.firestore()
    @Environment(\.presentationMode) var presentationMode // For Back Button
    
    var body: some View {
        ZStack {
            
 // **🚀 Modern Gradient Background**
 LinearGradient(
     gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)]),
     startPoint: .top,
     endPoint: .bottom
 )
 .ignoresSafeArea()
            NavigationView {
                VStack(spacing: 20) {
                    // Offline Status Indicator
                    if isOffline {
                        Text("You are currently offline")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    // Active Ride or Available Rides
                    
                        // Existing sections like ride handling
                        if let ride = activeRide {
                            activeRideView(ride: ride)
                        } else if availableRides.isEmpty && !isLoading {
                            noAvailableRidesView
                        } else {
                            availableRidesListView
                        }

                        Spacer()

                        // profileButton
                    actionButtons
 

 private var availableRidesListView: some View {
     List(availableRides) { ride in
         VStack(alignment: .leading, spacing: 5) {
             Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
             Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
             
             HStack {
                 Button("Accept Ride") {
                     acceptRide(ride: ride)
                 }
                 .buttonStyle(.borderedProminent)
                 
                 Button("Decline Ride") {
                     declineRide(ride: ride)
                 }
                 .buttonStyle(.bordered)
                 .foregroundColor(.red)
             }
         }
     }
 }
                    }
                .onAppear {
                    fetchDriverLocation()
                    fetchAvailableRides()
                }
                .navigationTitle("Driver Dashboard")
                .overlay(
                    isLoading ? ProgressView().scaleEffect(2) : nil
                )
                .alert(isPresented: .constant(errorMessage != nil), content: {
                    Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
                })
            }
        }
    }
}



// MARK: - Subviews
extension DriverDashboardView {
    private var noAvailableRidesView: some View {
        Text("No available rides.")
            .foregroundColor(.gray)
    }
    
    private var availableRidesListView: some View {
        List(availableRides) { ride in
            VStack(alignment: .leading, spacing: 5) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                
                HStack {
                    Button("Accept Ride") {
                        acceptRide(ride: ride)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Decline Ride") {
                        declineRide(ride: ride)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - New Profile and Ride History Buttons
    
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            
            // Profile Button
            HStack {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn)) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Online/Offline Status Indicator
                Circle()
                    .fill(isOffline ? Color.red : Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            
            // Ride History Button
            Button(action: {
                showRideHistoryView = true
            }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Ride History")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .sheet(isPresented: $showRideHistoryView) {
                RideHistoryView()  // Ensure RideHistoryView exists
            }
        }
        .onReceive(LocationManager.shared.$driverLocation) { location in
            DispatchQueue.main.async {
                isOffline = (location == nil)
                updateDriverStatus(isOnline: location != nil)
            }
        }
    }
    
    // MARK: - Navigate to AnsweringView
    private var answeringViewButton: some View {
        NavigationLink(destination: AnsweringView(isLoggedIn: $isLoggedIn)) {
            Text("View Ride Details")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
    
   
    
    
    
    private func completeRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "completed"
        ]) { error in
            if let error = error {
                errorMessage = "Error completing ride: \(error.localizedDescription)"
                return
            }
            
            // Reset activeRide to go back to available rides
            activeRide = nil
            
            // Optionally refresh available rides
            fetchAvailableRides()
        }
    }
    
    private func activeRideView(ride: RideRequest) -> some View {
        VStack(spacing: 10) {
            Text("🚖 Active Ride")
                .font(.headline)
                .bold()
            
            // Ensure locations are correctly retrieved
            if
               let pickupGeoPoint = ride.pickupLocation as? GeoPoint,
               let dropoffGeoPoint = ride.dropoffLocation as? GeoPoint,
               let driverLoc = driverLocation {
                
                let pickupCoordinate = CLLocationCoordinate2D(
                    latitude: pickupGeoPoint.latitude,
                    longitude: pickupGeoPoint.longitude
                )
                let dropoffCoordinate = CLLocationCoordinate2D(
                    latitude: dropoffGeoPoint.latitude,
                    longitude: dropoffGeoPoint.longitude
                )
                
                // Display MapView
                MapView(
                    userLocation: Binding.constant(pickupCoordinate),
                    destination: Binding.constant(dropoffCoordinate),
                    driverLocation: Binding.constant(driverLoc),
                    mapView: $mapView
                )
                .frame(height: 300)
                .cornerRadius(10)
                
                // Ride Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("📍 Pickup: \(ride.pickupAddress ?? "Unknown")")
                    Text("📍 Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                }
                
                // Start Navigation Button
                Button(action: {
                    startNavigation(driverLocation: driverLoc, pickupLocation: pickupCoordinate, dropoffLocation: dropoffCoordinate)
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Start Navigation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Complete Ride Button
                Button(action: {
                    completeRide(ride: ride)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Ride")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                Text("⚠️ Location data unavailable")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

 
 // MARK: - Functions
extension DriverDashboardView {
    private func fetchDriverLocation() {
        // Mock driver location (replace with actual location updates from a LocationManager)
        driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }
    
    private func fetchAvailableRides() {
        isLoading = true
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(
                        id: doc.documentID,
                        data: doc.data()
                    )
                }
            }
    }
    
    private func acceptRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "accepted",
            "driverId": "mockDriverId" // Replace with the actual driver ID
        ]) { error in
            if let error = error {
                errorMessage = "Error accepting ride: \(error.localizedDescription)"
                return
            }
            activeRide = ride
        }
    }
    
    private func declineRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "declined"
        ]) { error in
            if let error = error {
                errorMessage = "Error declining ride: \(error.localizedDescription)"
                return
            }
            availableRides.removeAll { $0.id == ride.id }
        }
    }
    
    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }
    private func startNavigation(driverLocation: CLLocationCoordinate2D, pickupLocation: CLLocationCoordinate2D, dropoffLocation: CLLocationCoordinate2D) {
        let driverPlacemark = MKPlacemark(coordinate: driverLocation)
        let pickupPlacemark = MKPlacemark(coordinate: pickupLocation)
        let dropoffPlacemark = MKPlacemark(coordinate: dropoffLocation)
        
        let driverMapItem = MKMapItem(placemark: driverPlacemark)
        driverMapItem.name = "Driver Location"
        
        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
        pickupMapItem.name = "Pickup Location"
        
        let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
        dropoffMapItem.name = "Dropoff Location"
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ]
        
        // Open Apple Maps with all three locations
        MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }
    
    
    private func logout() {
        do {
            try auth.signOut()
            isLoggedIn = false
        } catch {
            self.errorMessage = "Failed to log out."
        }
    }
}
*/


/* import SwiftUI
 import FirebaseFirestore
 import MapKit
 
 struct DriverDashboardView: View {
 @Binding var isLoggedIn: Bool
 @State private var availableRides: [RideRequest] = []
 @State private var activeRide: RideRequest? // Currently accepted ride
 @State private var mapView = MKMapView()
 @State private var isOffline: Bool = false // Track online/offline status
 @State private var driverLocation: CLLocationCoordinate2D?
 @State private var isLoading: Bool = false
 @State private var errorMessage: String?
 
 private let db = Firestore.firestore()
 @Environment(\.presentationMode) var presentationMode // For Back Button
 
 var body: some View {
 NavigationView {
 VStack(spacing: 20) {
 // Offline Status Indicator
 if isOffline {
 Text("You are currently offline")
 .foregroundColor(.red)
 .font(.subheadline)
 }
 
 // Active Ride or Available Rides
 if let ride = activeRide {
 activeRideView(ride: ride)
 } else if availableRides.isEmpty && !isLoading {
 noAvailableRidesView
 } else {
 availableRidesListView
 }
 
 Spacer()
 
 // Online/Offline Toggle
 toggleAvailabilityButton
 
 // Logout Button
 logoutButton
 }
 .onAppear {
 fetchDriverLocation()
 fetchAvailableRides()
 }
 .navigationTitle("Driver Dashboard")
 .overlay(
 isLoading ? ProgressView().scaleEffect(2) : nil
 )
 .alert(isPresented: .constant(errorMessage != nil), content: {
 Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
 })
 }
 }
 }
 
 // MARK: - Subviews
 extension DriverDashboardView {
 private var noAvailableRidesView: some View {
 Text("No available rides.")
 .foregroundColor(.gray)
 }
 
 private var availableRidesListView: some View {
 List(availableRides) { ride in
 VStack(alignment: .leading, spacing: 5) {
 Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
 Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
 
 HStack {
 Button("Accept Ride") {
 acceptRide(ride: ride)
 }
 .buttonStyle(.borderedProminent)
 
 Button("Decline Ride") {
 declineRide(ride: ride)
 }
 .buttonStyle(.bordered)
 .foregroundColor(.red)
 }
 }
 }
 }
 
 private var toggleAvailabilityButton: some View {
 Button(action: {
 isOffline.toggle()
 updateDriverStatus(isOnline: !isOffline)
 }) {
 Text(isOffline ? "Go Online" : "Go Offline")
 .frame(maxWidth: .infinity)
 .padding()
 .background(isOffline ? Color.green : Color.red)
 .foregroundColor(.white)
 .cornerRadius(10)
 }
 .padding()
 }
 
 private var logoutButton: some View {
 Button(action: logout) {
 Text("Logout")
 .frame(maxWidth: .infinity)
 .padding()
 .background(Color.blue)
 .foregroundColor(.white)
 .cornerRadius(10)
 }
 .padding()
 }
 
 private func activeRideView(ride: RideRequest) -> some View {
 VStack(spacing: 10) {
 Text("Active Ride").font(.headline)
 
 // MapView
 MapView(
 userLocation: Binding(
 get: { CLLocationCoordinate2D(latitude: ride.pickupLocation.latitude, longitude: ride.pickupLocation.longitude) },
 set: { _ in }
 ),
 destination: Binding(
 get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
 set: { _ in }
 ),
 driverLocation: Binding(
 get: { driverLocation },
 set: { driverLocation = $0 }
 ),
 mapView: $mapView
 )
 .frame(height: 300)
 .cornerRadius(10)
 
 VStack(alignment: .leading, spacing: 8) {
 Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
 Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
 }
 
 Button("Start Navigation") {
 startNavigation(to: CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude))
 }
 .buttonStyle(.borderedProminent)
 }
 }
 }
 
 // MARK: - Functions
 extension DriverDashboardView {
 private func fetchDriverLocation() {
 // Mock driver location (replace with actual location updates from a LocationManager)
 driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
 }
 
 private func fetchAvailableRides() {
 isLoading = true
 db.collection("rides")
 .whereField("status", isEqualTo: "requested")
 .addSnapshotListener { snapshot, error in
 isLoading = false
 if let error = error {
 errorMessage = "Error fetching rides: \(error.localizedDescription)"
 return
 }
 guard let documents = snapshot?.documents else { return }
 self.availableRides = documents.map { doc in
 RideRequest(
 id: doc.documentID,
 data: doc.data()
 )
 }
 }
 }
 
 private func acceptRide(ride: RideRequest) {
 db.collection("rides").document(ride.id).updateData([
 "status": "accepted",
 "driverId": "mockDriverId" // Replace with the actual driver ID
 ]) { error in
 if let error = error {
 errorMessage = "Error accepting ride: \(error.localizedDescription)"
 return
 }
 activeRide = ride
 }
 }
 
 private func declineRide(ride: RideRequest) {
 db.collection("rides").document(ride.id).updateData([
 "status": "declined"
 ]) { error in
 if let error = error {
 errorMessage = "Error declining ride: \(error.localizedDescription)"
 return
 }
 availableRides.removeAll { $0.id == ride.id }
 }
 }
 
 private func updateDriverStatus(isOnline: Bool) {
 db.collection("drivers").document("mockDriverId").updateData([
 "isOnline": isOnline
 ]) { error in
 if let error = error {
 errorMessage = "Failed to update driver status: \(error.localizedDescription)"
 }
 }
 }
 
 private func startNavigation(to destination: CLLocationCoordinate2D) {
 guard let driverLocation = driverLocation else {
 print("Driver location is missing.")
 return
 }
 
 guard let activeRide = activeRide else {
 print("Active ride is missing.")
 return
 }
 
 // Placemark for Driver's Current Location
 let driverPlacemark = MKPlacemark(coordinate: driverLocation)
 let driverMapItem = MKMapItem(placemark: driverPlacemark)
 driverMapItem.name = "Driver Location"
 
 // Placemark for Pickup Location
 let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
 latitude: activeRide.pickupLocation.latitude,
 longitude: activeRide.pickupLocation.longitude
 ))
 let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
 pickupMapItem.name = "Pickup Location"
 
 // Placemark for Dropoff Location
 let dropoffPlacemark = MKPlacemark(coordinate: destination)
 let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
 dropoffMapItem.name = "Dropoff Location"
 
 // Launch options
 let launchOptions: [String: Any] = [
 MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
 MKLaunchOptionsShowsTrafficKey: true
 ]
 
 // Open Apple Maps with the route
 MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
 }
 
 private func logout() {
 isLoggedIn = false
 }
 }*/

/*
// to be use as a setting view or answering view just in case if domething goes wrong
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest?
    @State private var mapView = MKMapView()
    @State private var isOffline: Bool = false
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var profileImageURL: String?
    @State private var licensePlate: String = ""
    @State private var vehicleModel: String = ""
    @State private var vehicleColor: String = ""
    @State private var showEarningsBreakdown: Bool = false
    @State private var earnings: DriverEarnings.Metrics = DriverEarnings.Metrics(totalEarnings: 0.0, completedRides: 0, bonuses: 0.0, unreadMessages: 0)
    @ObservedObject private var locationManager = LocationManager.shared
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // **Profile and Status Section**
                DriverProfileView(
                    licensePlate: $licensePlate,
                    vehicleModel: $vehicleModel,
                    vehicleColor: $vehicleColor,
                    imageUrl: profileImageURL,
                    isOffline: $isOffline
                )
                
                // **Earnings Dashboard**
                earningsDashboard
                
                // **Ride Handling Section**
                if let ride = activeRide {
                    activeRideView(ride: ride)
                        .transition(.slide)
                } else {
                    availableRidesSection
                }
                
                Spacer()
                
                // **Go Online / Offline Button**
                onlineOfflineButton
                
                // **Logout Button**
                logoutButton
            }
            .padding()
            .overlay(isLoading ? ProgressView().scaleEffect(2) : nil)
            .onAppear {
                setupLocationManager()
                fetchDriverProfile()
                fetchAvailableRides()
                fetchEarnings()
            }
            .alert(isPresented: .constant(errorMessage != nil)) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showEarningsBreakdown) {
                EarningsAnalyticsView(earnings: $earnings)
            }
        }
    }
    
    // **Earnings Dashboard**
    private var earningsDashboard: some View {
        VStack {
            Text("Earnings Summary")
                .font(.headline)
                .foregroundColor(.white)
            Text("$\(earnings.totalEarnings, specifier: "%.2f")")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            
            Button(action: {
                showEarningsBreakdown.toggle()
            }) {
                Text("View Details")
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .shadow(radius: 5)
        )
    }
    
    // **Available Rides Section**
    private var availableRidesSection: some View {
        List(availableRides) { ride in
            VStack(alignment: .leading) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                
                HStack {
                    Button("Accept Ride") {
                        acceptRide(ride: ride)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Decline") {
                        declineRide(ride: ride)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // **Active Ride View**
    private func activeRideView(ride: RideRequest) -> some View {
        VStack {
            Text("🚖 Active Ride")
                .font(.title2)
                .bold()
            
            MapView(
                userLocation: Binding(
                    get: { driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) },
                    set: { driverLocation = $0 }
                ),
                destination: Binding(
                    get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
                    set: { _ in }
                ),
                driverLocation: Binding(
                    get: { driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) },
                    set: { driverLocation = $0 }
                ),
                mapView: $mapView
            )
            .frame(height: 250)
            .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
            }
            .padding()
            
            Button("Start Navigation") {
                let dropoffCoordinate = CLLocationCoordinate2D(
                    latitude: ride.dropoffLocation.latitude,
                    longitude: ride.dropoffLocation.longitude
                )
                startNavigation(to: dropoffCoordinate)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
    }
    
    // **Go Online / Offline Button**
    private var onlineOfflineButton: some View {
        Button(action: {
            isOffline.toggle()
            updateDriverStatus(isOnline: !isOffline)
        }) {
            Text(isOffline ? "Go Online" : "Go Offline")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isOffline ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
    
    // **Logout Button**
    private var logoutButton: some View {
        Button(action: logout) {
            Text("Logout")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // **Fetch Driver Profile**
    private func fetchDriverProfile() {
        guard let userId = auth.currentUser?.uid else { return }
        isLoading = true
        
        db.collection("drivers").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error fetching profile: \(error.localizedDescription)"
                    return
                }
                
                if let data = snapshot?.data() {
                    self.profileImageURL = data["profileImageURL"] as? String ?? ""
                    
                    if let vehicleInfo = data["vehicleInfo"] as? [String: String] {
                        self.licensePlate = vehicleInfo["licensePlate"] ?? "Unknown"
                        self.vehicleModel = vehicleInfo["vehicleModel"] ?? "Unknown"
                        self.vehicleColor = vehicleInfo["vehicleColor"] ?? "Unknown"
                    }
                }
            }
        }
    }
    private func setupLocationManager() {
        locationManager.requestAuthorization() // ✅ Fix: Call the correct function
        locationManager.startUpdatingLocation()
    }
    private func fetchAvailableRides() {
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(id: doc.documentID, data: doc.data())
                }
            }
    }
    private func fetchEarnings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching earnings: \(error.localizedDescription)"
                return
            }
            if let data = snapshot?.data() {
                self.earnings = DriverEarnings.Metrics(
                    totalEarnings: data["totalEarnings"] as? Double ?? 0.0,
                    completedRides: data["completedRides"] as? Int ?? 0,
                    bonuses: data["bonuses"] as? Double ?? 0.0,
                    unreadMessages: data["unreadMessages"] as? Int ?? 0
                )
            }
        }
    }
    
    private func logout() {
        do {
            try auth.signOut()
            isLoggedIn = false
        } catch {
            self.errorMessage = "Failed to log out."
        }
    }
    
    private func acceptRide(ride: RideRequest) {
        activeRide = ride
    }
    
    private func declineRide(ride: RideRequest) {
        availableRides.removeAll { $0.id == ride.id }
    }
    
    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }
    
    private func startNavigation(to destination: CLLocationCoordinate2D) {
        guard let driverLocation = driverLocation else {
            print("Driver location is missing.")
            return
        }
        
        guard let activeRide = activeRide else {
            print("Active ride is missing.")
            return
        }
        
        // Placemark for Driver's Current Location
        let driverPlacemark = MKPlacemark(coordinate: driverLocation)
        let driverMapItem = MKMapItem(placemark: driverPlacemark)
        driverMapItem.name = "Driver Location"
        
        // Placemark for Pickup Location
        let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: activeRide.pickupLocation.latitude,
            longitude: activeRide.pickupLocation.longitude
        ))
        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
        pickupMapItem.name = "Pickup Location"
        
        // Placemark for Dropoff Location
        let dropoffPlacemark = MKPlacemark(coordinate: destination)
        let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
        dropoffMapItem.name = "Dropoff Location"
        
        // Launch options
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ]
        
        // Open Apple Maps with the route
        MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }
}  // view to be use as a replacement for the Answering view or setting view. */  //hjidknshghbcnfmef smncffHFDHfnsncmaNANFKSFNSOK:hbdhcd jcjnNDBJCBODVN
    
/*
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest?
    @State private var isOffline: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var profileImageURL: String?
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var mapView = MKMapView()
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var showEarningsBreakdown: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var earnings: DriverEarnings.Metrics =  DriverEarnings.Metrics (totalEarnings: 0.0, completedRides: 0,  bonuses: 0.0, unreadMessages: 0)
    @State private var driver: Driver?
    @State private var licensePlate: String = "Unknown"
    @State private var vehicleModel: String = "Unknown"
    @State private var vehicleColor: String = "Unknown"
    
    // **Dynamic Pricing Controls**
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0
    @State private var preferredRouteType: RouteType = .fastest
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            PulsatingGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                driverStatusHeader
                    .modifier(FloatingCardEffect())
                
                Group {
                    if let ride = activeRide {
                        activeRideView(ride: ride)
                           .transition(.asymmetric(
                                insertion: .skewedSlide(.trailing),
                                removal: .skewedSlide(.leading)
                            ))

               
                    } else {
                        rideOpportunitiesGrid
                    }
                }
                .animation(.spring(), value: activeRide)
                
                earningsDashboard
                    .modifier(ChartElevationEffect())
                
                Spacer()
                
                actionPanel
                    .modifier(ButtonStackEffect())
            }
            .padding(.horizontal)
        }
        .overlay(loadingOverlay)
        .alert(errorMessage ?? "", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {}
        .sheet(isPresented: $showEarningsBreakdown) {
            EarningsAnalyticsView(earnings: $earnings)
              //  .transition(.sheetSlide)
                .transition(.move(edge: .bottom))
        }
        .onAppear(perform: initializeDashboard)
        .onReceive(locationManager.$driverLocation) { location in
            if let coordinate = location {
                let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                handleLocationUpdate(clLocation)
            }
        }
    }
}





// MARK: - 🎬 Advanced Animations
extension DriverDashboardView {
    private var driverStatusHeader: some View {
        HStack(spacing: 16) {
            DriverProfileView(
                licensePlate: $licensePlate,
                vehicleModel: $vehicleModel,
                vehicleColor: $vehicleColor,
                imageUrl: profileImageURL, isOffline: $isOffline
            )
            .animation(.bouncy, value: profileImageURL)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("GoMoto Pro Driver")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        .transition(.textFade)
                    
                    OnlineStatusIndicator(isOnline: !isOffline)
                        .animation(.pulse, value: isOffline)
                }
                
                DriverPerformanceMeter(metrics: earnings)
                    .animation(.ripple(), value: earnings.totalEarnings)
                    .onAppear {
                        print("Earnings: \(earnings)")
                    }
                PricingControlPanel(
                    baseRate: $baseRateMultiplier,
                    surge: $surgePricing
                )
                .animation(.interactiveSpring, value: surgePricing)
            }
            
            Spacer()
        }
        .padding()
        .background(VisualEffectView(effect: .systemUltraThinMaterial))
        .cornerRadius(20)
        .modifier(NeumorphicShadow())
    }
    
    private var rideOpportunitiesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
                ForEach(availableRides.indices, id: \.self) { index in
                    let ride = availableRides[index]
                    RideOpportunityCard(ride: ride, acceptRide: {
                        acceptRide(ride)
                    }, declineRide: {
                        declineRide(ride)
                    })
                    .transition(
                        .asymmetric(
                            insertion: .cardInsertion(index: index),
                            removal: .cardRemoval
                        )
                    )
                    .animation(.smooth(duration: 0.4, extraBounce: 0.2).delay(Double(index) * 0.05), value: availableRides)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    private func declineRide(_ ride: RideRequest) {
        availableRides.removeAll { $0.id == ride.id }
    }
    
    
    private func activeRideView(ride: RideRequest) -> some View {
        VStack(spacing: 10) {
            Text("🚖 Active Ride")
                .font(.title2)
                .bold()

            if let dropoffGeoPoint = ride.dropoffLocation as? GeoPoint {
                let dropoffCoordinate = CLLocationCoordinate2D(latitude: dropoffGeoPoint.latitude, longitude: dropoffGeoPoint.longitude)
                
                if let currentDriverLocation = driverLocation {
                    MapView(
                        userLocation: Binding.constant(currentDriverLocation),
                        destination: Binding.constant(dropoffCoordinate),
                        driverLocation: Binding.constant(currentDriverLocation),
                        mapView: $mapView
                    )
                    .frame(height: 250)
                    .cornerRadius(10)
                } else {
                    Text("Driver location unavailable")
                        .foregroundColor(.red)
                }
            } else {
                Text("Invalid dropoff location data")
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
            }
            .padding()

            HStack(spacing: 15) {
                Button("Start Navigation") {
                    if let dropoffGeoPoint = ride.dropoffLocation as? GeoPoint {
                        let dropoffCoordinate = CLLocationCoordinate2D(latitude: dropoffGeoPoint.latitude, longitude: dropoffGeoPoint.longitude)
                        startNavigation(to: dropoffCoordinate)
                    } else {
                        print("Invalid dropoff location")
                    }
                }
                .buttonStyle(.borderedProminent)

                // Emergency SOS Button
                Button(action: {
                    triggerEmergencyProtocol()
                }) {
                    Text("🚨 SOS")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
    }

    // MARK: - Emergency Protocol Function
    private func triggerEmergencyProtocol() {
        // Example: Call emergency services or send the current location to a trusted contact
        guard let currentLocation = driverLocation else {
            print("Driver location unavailable for emergency.")
            return
        }
        
        // Send location to emergency contact or authorities
        sendLocationToEmergencyContact(currentLocation)
        print("Emergency protocol triggered. Location shared with emergency contact.")
    }

    private func sendLocationToEmergencyContact(_ location: CLLocationCoordinate2D) {
        // This could be an API call, SMS integration, or Firebase update for emergency contacts
        // For now, we simulate the process with a print statement
        print("Location sent: \(location.latitude), \(location.longitude)")
    }
   /* private func activeRideView(ride: RideRequest) -> some View {
        VStack(spacing: 16) {
            NavigationMapView(
                userLocation: locationManager.driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                destination: CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude)
            )
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RideNavigationOverlay(ride: ride)
                    .transition(.scale)
            )
            .modifier(MapPulseEffect())
            
            RideControlPanel(
                ride: ride,
                onComplete: completeRide,
                onEmergency: triggerEmergencyProtocol
            )
            .transition(.buttonCluster)
        }
    }*/
    
    
    private func fetchDriverProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("drivers").document(userId).getDocument { snapshot, error in
            // 🔴 Error Handling
            if let error = error {
                print("❌ Error fetching driver profile: \(error.localizedDescription)")
                return
            }
            
            // ✅ Extract Data Safely
            guard let data = snapshot?.data() else {
                print("❌ No driver data found for user \(userId)")
                return
            }
            
            DispatchQueue.main.async {
                // 🏎️ Update Driver Info
                self.driver = Driver(
                    licensePlate: data["licensePlate"] as? String ?? "Unknown",
                    vehicleModel: data["vehicleModel"] as? String ?? "Unknown",
                    vehicleColor: data["vehicleColor"] as? String ?? "Unknown"
                )
                
                // 🖼️ Update Profile Image URL
                self.profileImageURL = data["profileImageURL"] as? String ?? ""
                
                // 💰 Update Earnings
                self.earnings = DriverEarnings.Metrics(
                    totalEarnings: data["totalEarnings"] as? Double ?? 0.0,
                    completedRides: data["completedRides"] as? Int ?? 0,
                    bonuses: data["bonuses"] as? Double ?? 0.0,
                    unreadMessages: data["unreadMessages"] as? Int ?? 0 // Ensure this field exists in Firestore
                )
            }
        }
    }
    private func setupFirestoreListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("rides")
            .whereField("driverId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to ride updates: \(error.localizedDescription)")
                    return
                }
                if let documents = snapshot?.documents {
                    self.availableRides = documents.map { RideRequest(doc: $0) }
                }
            }
    }
    
    
   

    private func configureDynamicPricing() {
        // Example: Surge pricing multiplier based on available rides
        let baseRate: Double = 1.0
        let rideCount = availableRides.count
        
        if rideCount > 10 {
            surgePricing = baseRate * 1.5  // High demand
        } else if rideCount < 3 {
            surgePricing = baseRate * 0.8  // Low demand
        } else {
            surgePricing = baseRate
        }
    }
    private func setupPerformanceMonitoring() {
        print("Performance monitoring initialized.")
        // You can integrate Firebase Performance Monitoring or logging systems here.
    }
    private func startNavigation(to destination: CLLocationCoordinate2D) {
    guard let driverLocation = driverLocation else {
    print("Driver location is missing.")
    return
    }
    
    guard let activeRide = activeRide else {
    print("Active ride is missing.")
    return
    }
    
    // Placemark for Driver's Current Location
    let driverPlacemark = MKPlacemark(coordinate: driverLocation)
    let driverMapItem = MKMapItem(placemark: driverPlacemark)
    driverMapItem.name = "Driver Location"
    
    // Placemark for Pickup Location
    let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
    latitude: activeRide.pickupLocation.latitude,
    longitude: activeRide.pickupLocation.longitude
    ))
    let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
    pickupMapItem.name = "Pickup Location"
    
    // Placemark for Dropoff Location
    let dropoffPlacemark = MKPlacemark(coordinate: destination)
    let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
    dropoffMapItem.name = "Dropoff Location"
    
    // Launch options
    let launchOptions: [String: Any] = [
    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
    MKLaunchOptionsShowsTrafficKey: true
    ]
    
    // Open Apple Maps with the route
    MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }
    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }
    
    
    private func initializeDashboard() {
        fetchDriverProfile()
        setupFirestoreListeners()
        configureDynamicPricing()
        setupPerformanceMonitoring()
    }
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    ProgressView("Loading...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private var earningsDashboard: some View {
        EarningsGraphView(earnings: earnings)
            .onTapGesture { withAnimation(.smooth) { showEarningsBreakdown.toggle() } }
            .modifier(ChartMorphEffect())
    }
    
    private var actionPanel: some View {
        HStack(spacing: 16) {
            DynamicToggleButton(
                isOn: $isOffline,
                onLabel: "Go Offline",
                offLabel: "Go Online",
                onColor: .red,
                offColor: .green
            )
            .animation(.smooth, value: isOffline)
            .onChange(of: isOffline) { updateDriverStatus(!$0) }
            
            NavigationLink {
                DriverInboxView()
            } label: {
                if #available(iOS 17.0, *) {
                    Image(systemName: "bell.badge")
                        .symbolEffect(.bounce, options: .repeating, value: earnings.unreadMessages ?? 0)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                } else {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                Button(action: {
                    print("Button tapped")
                }) {
                    Text("Tap Me")
                }
                .buttonStyle(BouncyButtonStyle())
            }
            .padding(.vertical)
        }
    }
}
extension AnyTransition {
    static func cardInsertion(index: Int) -> AnyTransition {
        .opacity
            .combined(with: .scale(scale: 0.95 + 0.05 * Double(index)))
    }

    static var cardRemoval: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.9))
    }
}
extension DriverDashboardView {
    struct DriverPerformanceMeter: View {
        let metrics: DriverEarnings.Metrics

        var body: some View {
            VStack {
                HStack {
                    Text("Completed Rides: \(metrics.completedRides)")
                    Spacer()
                    Text("Earnings: $\(metrics.totalEarnings, specifier: "%.2f")")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.2)))
                .shadow(radius: 5)
            }
            .padding()
        }
    }
}



// MARK: - 🚀 Business Logic
extension DriverDashboardView {
    private func acceptRide(_ ride: RideRequest) {
        withAnimation {
            activeRide = ride
            db.collection("rides").document(ride.id).updateData([
                "status": "accepted",
                "driverId": currentUserId,
                "acceptedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    private func completeRide() {
        guard let ride = activeRide else { return }
        
        
        let finalFare = ride.baseFare * baseRateMultiplier * surgePricing
        let earningsUpdate: [String: Any] = [
            "totalEarnings": earnings.totalEarnings + finalFare, // No .wrappedValue needed
            "completedRides": earnings.completedRides + 1,
            "bonuses": earnings.bonuses
        ]
    
       
        
        
        db.collection("rides").document(ride.id).updateData([
            "status": "completed",
            "finalFare": finalFare
        ])
        
        db.collection("drivers").document(currentUserId)
            .updateData(earningsUpdate)
        
        withAnimation {
            activeRide = nil
            surgePricing = 1.0
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        driverLocation = location.coordinate
    }
    
    private func updateDriverStatus(_ online: Bool) {
        db.collection("drivers").document(currentUserId)
            .updateData(["isOnline": online])
    }
}

// MARK: - 🔥 Supporting Features
/*extension DriverDashboardView {
    private var currentUserId: String {
        auth.currentUser?.uid ?? ""
    
    
       
        
       guard let ride = activeRide else {
            print("🚨 Error: No active ride found")
            return
        }

        EmergencySystem.shared.triggerEmergency(
            userLocation: "\(driverLocation.latitude), \(driverLocation.longitude)", // Convert to String
            rideDetails: ride.id // Assuming the function expects a ride ID, adjust as needed
        )
    }*/
// MARK: - 🔥 Supporting Features
extension DriverDashboardView {
    
    // Fetch Current User ID
    private var currentUserId: String {
        auth.currentUser?.uid ?? ""
    }
    
    // Trigger Emergency Protocol
    private func triggerEmergency() {
        guard let ride = activeRide else {
            print("🚨 Error: No active ride found")
            return
        }

        guard let currentDriverLocation = driverLocation else {
            print("❗ Driver location is unavailable.")
            return
        }

        EmergencySystem.shared.triggerEmergency(
            userLocation: "\(currentDriverLocation.latitude), \(currentDriverLocation.longitude)",
            rideDetails: ride.id
        )
    }
    
    // Handle Location Updates from Firebase
    private func handleLocationUpdate(_ location: CLLocation) {
        db.collection("drivers").document(currentUserId).updateData([
            "location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("❗ Error updating location: \(error.localizedDescription)")
            } else {
                print("✅ Location updated successfully.")
            }
        }
    }
    
    // Fetch Driver's Current Location
    private func fetchDriverLocation() {
        guard let userId = auth.currentUser?.uid else {
            print("❗ User not authenticated.")
            return
        }
        
        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❗ Error fetching driver location: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), let location = data["location"] as? GeoPoint {
                driverLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            } else {
                print("❗ No location data found.")
            }
        }
    }

    
/*    private func handleLocationUpdate(_ location: CLLocation) {
        db.collection("drivers").document(currentUserId)
            .updateData([
                "location": GeoPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ),
                "lastUpdated": FieldValue.serverTimestamp()
            ])
    }
}*/
// MARK: - Functions
/*extension DriverDashboardView {
    private func fetchDriverLocation() {
        // Mock driver location (replace with actual location updates from a LocationManager)
        driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }*/
    
    private func fetchAvailableRides() {
        isLoading = true
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(
                        id: doc.documentID,
                        data: doc.data()
                    )
                }
            }
    }
    
}
/*// MARK: - **Competitive Edge Over Uber**
### **🚀 Features that Give GoMoto an Advantage:**
- **Surge Pricing Transparency**
  - Uber hides pricing; **GoMoto gives drivers control**
- **Earnings & Fare Insights**
  - Real-time earnings tracking
  - Drivers **see the full fare breakdown** before accepting
- **AI-powered Shift Optimization**
  - Heatmaps **predict** high-demand areas
  - Auto-recommend **profitable rides only**
- **Multiple Ride Acceptance**
  - Accept **batch rides** to optimize shift efficiency
- **Fuel Cost Optimization**
  - AI selects **fuel-efficient routes** to maximize profits

---

### ✅ **Next Steps**
1️⃣ **Replace your existing `DriverDashboardView` with this version**
2️⃣ **Test ride acceptance, navigation, and surge pricing**
3️⃣ **Confirm real-time updates are working**
4️⃣ **Fine-tune pricing multipliers for best profitability**

💡 **This will make GoMoto the most driver-friendly app on the market!** 🚀
*/

/*import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest?
    @State private var mapView = MKMapView()
    @State private var isOffline: Bool = false
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var profileImageURL: String?
    @State private var earnings: Double = 0.0
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var showNavigation: Bool = false

    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // **Profile and Availability Status**
                headerSection

                // **Ride Details**
                if let ride = activeRide {
                    activeRideView(ride: ride)
                        .transition(.slide)
                } else {
                    availableRidesSection
                }

                // **Earnings Dashboard**
                earningsSection

                Spacer()

                // **Floating Action Button for Online/Offline**
                onlineOfflineButton

                // **Logout Button**
                logoutButton
            }
            .padding()
            .overlay(
                isLoading ? ProgressView().scaleEffect(2) : nil
            )
            .onAppear {
                setupLocationManager()
                fetchDriverLocation()
                fetchAvailableRides()
                fetchDriverProfile()
                fetchEarnings()
                setupPushNotifications()
            }
            .alert(isPresented: .constant(errorMessage != nil)) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showNavigation) {
                if let ride = activeRide {
                    NavigationView {
                        Text("Navigation for \(ride.pickupAddress ?? "Pickup")")
                    }
                } else {
                    EmptyView() // Ensure SwiftUI always has a valid View
                }
            }
        }
       
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        driverLocation = location.coordinate
    }
    private func activeRideView(ride: RideRequest) -> some View {
        VStack {
            Text("🚖 Active Ride")
                .font(.title2)
                .bold()

            MapView(
                userLocation: Binding(
                    get: { driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) },
                    set: { driverLocation = $0 }
                ),
                destination: Binding(
                    get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
                    set: { _ in }
                ),
                driverLocation: Binding(
                    get: { driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) },
                    set: { driverLocation = $0 }
                ),
                mapView: $mapView
            )
            .frame(height: 250)
            .cornerRadius(10)

            VStack(alignment: .leading) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
            }
            .padding()

            Button("Start Navigation") {
                let dropoffCoordinate = CLLocationCoordinate2D(
                    latitude: ride.dropoffLocation.latitude,
                    longitude: ride.dropoffLocation.longitude
                )
                startNavigation(to: dropoffCoordinate)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
    }
    private var availableRidesSection: some View {
        List(availableRides) { ride in
            VStack(alignment: .leading) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")

                HStack {
                    Button("Accept Ride") {
                        acceptRide(ride: ride)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Decline") {
                        declineRide(ride: ride)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
    }
    private var onlineOfflineButton: some View {
        Button(action: {
            isOffline.toggle()
            updateDriverStatus(isOnline: !isOffline)
        }) {
            Text(isOffline ? "Go Online" : "Go Offline")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isOffline ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
    private func setupLocationManager() {
        locationManager.requestAuthorization() // ✅ Fix: Call the correct function
        locationManager.startUpdatingLocation()
    }
    private func fetchDriverLocation() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching location: \(error.localizedDescription)"
                return
            }
            if let data = snapshot?.data(), let location = data["location"] as? GeoPoint {
                driverLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            }
        }
    }
   
    private func fetchAvailableRides() {
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(id: doc.documentID, data: doc.data())
                }
            }
    }
    private func fetchEarnings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching earnings: \(error.localizedDescription)"
                return
            }
            if let data = snapshot?.data(), let earnings = data["earnings"] as? Double {
                self.earnings = earnings
            }
        }
    }
   
}

// MARK: - **Header Section**
extension DriverDashboardView {
    private var headerSection: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("GoMoto Driver")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(isOffline ? "Offline" : "Online")
                        .foregroundColor(isOffline ? .red : .green)
                        .font(.subheadline)
                        .bold()
                }
                Spacer()

                // Profile Picture (Driver Image)
                if let imageUrl = profileImageURL, !imageUrl.isEmpty {
                    WebImage(url: URL(string: imageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .shadow(radius: 5)
        )
    }
}

// MARK: - **Earnings Section**
extension DriverDashboardView {
    private var earningsSection: some View {
        VStack {
            Text("Earnings")
                .font(.headline)
                .foregroundColor(.white)
            Text("$\(earnings, specifier: "%.2f")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .shadow(radius: 5)
        )
    }
}

// MARK: - **Logout Button**
extension DriverDashboardView {
    private var logoutButton: some View {
        Button(action: logout) {
            Text("Logout")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - **Fetch Driver Profile**
extension DriverDashboardView {
    private func fetchDriverProfile() {
        guard let userId = auth.currentUser?.uid else { return }

        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching profile: \(error.localizedDescription)"
                return
            }
            if let data = snapshot?.data(), let imageUrl = data["profileImageURL"] as? String {
                profileImageURL = imageUrl
            }
        }
    }

    private func logout() {
        do {
            try auth.signOut()
            isLoggedIn = false
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = "Failed to log out."
        }
    }
}

// MARK: - **Push Notifications**
extension DriverDashboardView {
    private func setupPushNotifications() {
        Messaging.messaging().token { token, error in
            if let error = error {
                errorMessage = "Error fetching FCM token: \(error.localizedDescription)"
                return
            }
            if let token = token {
                updateFCMToken(token: token)
            }
        }
    }
    
    private func updateFCMToken(token: String) {
        guard let userId = auth.currentUser?.uid else { return }
        db.collection("drivers").document(userId).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                errorMessage = "Error updating FCM token: \(error.localizedDescription)"
            }
        }
    }
   // accept ride func
 private func acceptRide(ride: RideRequest) {
     activeRide = ride
 }

 private func declineRide(ride: RideRequest) {
     availableRides.removeAll { $0.id == ride.id }
 }
 

    private func startNavigation(to destination: CLLocationCoordinate2D) {
    guard let driverLocation = driverLocation else {
    print("Driver location is missing.")
    return
    }
    
    guard let activeRide = activeRide else {
    print("Active ride is missing.")
    return
    }
    
    // Placemark for Driver's Current Location
    let driverPlacemark = MKPlacemark(coordinate: driverLocation)
    let driverMapItem = MKMapItem(placemark: driverPlacemark)
    driverMapItem.name = "Driver Location"
    
    // Placemark for Pickup Location
    let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
    latitude: activeRide.pickupLocation.latitude,
    longitude: activeRide.pickupLocation.longitude
    ))
    let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
    pickupMapItem.name = "Pickup Location"
    
    // Placemark for Dropoff Location
    let dropoffPlacemark = MKPlacemark(coordinate: destination)
    let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
    dropoffMapItem.name = "Dropoff Location"
    
    // Launch options
    let launchOptions: [String: Any] = [
    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
    MKLaunchOptionsShowsTrafficKey: true
    ]
    
    // Open Apple Maps with the route
    MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }
    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }
   
    
}
*/
/*import SwiftUI
import FirebaseFirestore
import MapKit

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest?
    @State private var mapView = MKMapView()
    @State private var isOffline: Bool = false
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // **Profile and Availability Status**
                headerSection

                // **Ride Details**
                if let ride = activeRide {
                    activeRideView(ride: ride)
                        .transition(.slide)
                } else {
                    availableRidesSection
                }

                Spacer()

                // **Floating Action Button for Online/Offline**
                onlineOfflineButton

                // **Logout Button**
                logoutButton
            }
            .padding()
            .overlay(
                isLoading ? ProgressView().scaleEffect(2) : nil
            )
            .onAppear {
                fetchDriverLocation()
                fetchAvailableRides()
            }
        }
    }
}

// MARK: - **Header Section**
extension DriverDashboardView {
    private var headerSection: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("GoMoto Driver")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(isOffline ? "Offline" : "Online")
                        .foregroundColor(isOffline ? .red : .green)
                        .font(.subheadline)
                        .bold()
                }
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .shadow(radius: 5)
        )
    }
}

// MARK: - **Ride Requests & Active Ride**
extension DriverDashboardView {
    private var availableRidesSection: some View {
        VStack {
            if availableRides.isEmpty && !isLoading {
                Text("No available rides at the moment.")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
                    .padding()
            } else {
                List(availableRides) { ride in
                    rideCard(ride: ride)
                        .listRowBackground(Color.clear)
                        .transition(.opacity)
                }
                .background(Color.black.opacity(0.2))
                .cornerRadius(15)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func rideCard(ride: RideRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📍 Pickup: \(ride.pickupAddress ?? "Unknown")")
                .fontWeight(.bold)
            Text("🏁 Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                .foregroundColor(.white.opacity(0.7))

            HStack {
                Button("Accept") {
                    acceptRide(ride: ride)
                }
                .buttonStyle(RideButtonStyle(color: .green))

                Button("Decline") {
                    declineRide(ride: ride)
                }
                .buttonStyle(RideButtonStyle(color: .red))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
    }

    private func activeRideView(ride: RideRequest) -> some View {
        VStack(spacing: 10) {
            Text("🚖 Active Ride")
                .font(.title2)
                .bold()
                .foregroundColor(.white)

            // **Map with Route**
            MapView(
                userLocation: Binding(
                    get: { CLLocationCoordinate2D(latitude: ride.pickupLocation.latitude, longitude: ride.pickupLocation.longitude) },
                    set: { _ in }
                ),
                destination: Binding(
                    get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
                    set: { _ in }
                ),
                driverLocation: Binding(
                    get: { driverLocation },
                    set: { driverLocation = $0 }
                ),
                mapView: $mapView
            )
            .frame(height: 300)
            .cornerRadius(12)

            Button("Start Navigation") {
                startNavigation(to: CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude))
            }
            .buttonStyle(RideButtonStyle(color: .blue))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.black.opacity(0.3)))
    }
}

// MARK: - **Floating Online/Offline Button**
extension DriverDashboardView {
    private var onlineOfflineButton: some View {
        Button(action: {
            isOffline.toggle()
            updateDriverStatus(isOnline: !isOffline)
        }) {
            Image(systemName: isOffline ? "power.circle.fill" : "power.circle")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(isOffline ? .green : .red)
                .background(Circle().fill(Color.white.opacity(0.2)))
                .shadow(radius: 5)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - **Logout Button**
extension DriverDashboardView {
    private var logoutButton: some View {
        Button(action: logout) {
            Text("Logout")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - **Custom Button Style**
struct RideButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
    }
}

// MARK: - **Functions**
extension DriverDashboardView {
    private func fetchDriverLocation() {
        driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }

    private func fetchAvailableRides() {
        isLoading = true
        db.collection("rides").whereField("status", isEqualTo: "requested").addSnapshotListener { snapshot, error in
            isLoading = false
            guard let documents = snapshot?.documents else { return }
            self.availableRides = documents.map { RideRequest(id: $0.documentID, data: $0.data()) }
        }
    }

    private func acceptRide(ride: RideRequest) {
        activeRide = ride
    }

    private func declineRide(ride: RideRequest) {
        availableRides.removeAll { $0.id == ride.id }
    }

    private func logout() {
        isLoggedIn = false
    }
    private func startNavigation(to destination: CLLocationCoordinate2D) {
        guard let driverLocation = driverLocation else {
            print("Driver location is missing.")
            return
        }

        guard let activeRide = activeRide else {
            print("Active ride is missing.")
            return
        }

        // Placemark for Driver's Current Location
        let driverPlacemark = MKPlacemark(coordinate: driverLocation)
        let driverMapItem = MKMapItem(placemark: driverPlacemark)
        driverMapItem.name = "Driver Location"

        // Placemark for Pickup Location
        let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: activeRide.pickupLocation.latitude,
            longitude: activeRide.pickupLocation.longitude
        ))
        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
        pickupMapItem.name = "Pickup Location"

        // Placemark for Dropoff Location
        let dropoffPlacemark = MKPlacemark(coordinate: destination)
        let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
        dropoffMapItem.name = "Dropoff Location"

        // Launch options
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ]

        // Open Apple Maps with the route
        MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }
    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }

}*/

/*
import SwiftUI
import FirebaseFirestore
import MapKit

struct DriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest? // Currently accepted ride
    @State private var mapView = MKMapView()
    @State private var isOffline: Bool = false // Track online/offline status
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let db = Firestore.firestore()
    @Environment(\.presentationMode) var presentationMode // For Back Button

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Offline Status Indicator
                if isOffline {
                    Text("You are currently offline")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }

                // Active Ride or Available Rides
                if let ride = activeRide {
                    activeRideView(ride: ride)
                } else if availableRides.isEmpty && !isLoading {
                    noAvailableRidesView
                } else {
                    availableRidesListView
                }

                Spacer()

                // Online/Offline Toggle
                toggleAvailabilityButton

                // Logout Button
                logoutButton
            }
            .onAppear {
                fetchDriverLocation()
                fetchAvailableRides()
            }
            .navigationTitle("Driver Dashboard")
            .overlay(
                isLoading ? ProgressView().scaleEffect(2) : nil
            )
            .alert(isPresented: .constant(errorMessage != nil), content: {
                Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
            })
        }
    }
}

// MARK: - Subviews
extension DriverDashboardView {
    private var noAvailableRidesView: some View {
        Text("No available rides.")
            .foregroundColor(.gray)
    }

    private var availableRidesListView: some View {
        List(availableRides) { ride in
            VStack(alignment: .leading, spacing: 5) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")

                HStack {
                    Button("Accept Ride") {
                        acceptRide(ride: ride)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Decline Ride") {
                        declineRide(ride: ride)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
    }

    private var toggleAvailabilityButton: some View {
        Button(action: {
            isOffline.toggle()
            updateDriverStatus(isOnline: !isOffline)
        }) {
            Text(isOffline ? "Go Online" : "Go Offline")
                .frame(maxWidth: .infinity)
                .padding()
                .background(isOffline ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }

    private var logoutButton: some View {
        Button(action: logout) {
            Text("Logout")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }

    private func activeRideView(ride: RideRequest) -> some View {
        VStack(spacing: 10) {
            Text("Active Ride").font(.headline)

            // MapView
            MapView(
                userLocation: Binding(
                    get: { CLLocationCoordinate2D(latitude: ride.pickupLocation.latitude, longitude: ride.pickupLocation.longitude) },
                    set: { _ in }
                ),
                destination: Binding(
                    get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
                    set: { _ in }
                ),
                driverLocation: Binding(
                    get: { driverLocation },
                    set: { driverLocation = $0 }
                ),
                mapView: $mapView
            )
            .frame(height: 300)
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
            }

            Button("Start Navigation") {
                startNavigation(to: CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude))
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Functions
extension DriverDashboardView {
    private func fetchDriverLocation() {
        // Mock driver location (replace with actual location updates from a LocationManager)
        driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }

    private func fetchAvailableRides() {
        isLoading = true
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(
                        id: doc.documentID,
                        data: doc.data()
                    )
                }
            }
    }

    private func acceptRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "accepted",
            "driverId": "mockDriverId" // Replace with the actual driver ID
        ]) { error in
            if let error = error {
                errorMessage = "Error accepting ride: \(error.localizedDescription)"
                return
            }
            activeRide = ride
        }
    }

    private func declineRide(ride: RideRequest) {
        db.collection("rides").document(ride.id).updateData([
            "status": "declined"
        ]) { error in
            if let error = error {
                errorMessage = "Error declining ride: \(error.localizedDescription)"
                return
            }
            availableRides.removeAll { $0.id == ride.id }
        }
    }

    private func updateDriverStatus(isOnline: Bool) {
        db.collection("drivers").document("mockDriverId").updateData([
            "isOnline": isOnline
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update driver status: \(error.localizedDescription)"
            }
        }
    }

    private func startNavigation(to destination: CLLocationCoordinate2D) {
        guard let driverLocation = driverLocation else {
            print("Driver location is missing.")
            return
        }

        guard let activeRide = activeRide else {
            print("Active ride is missing.")
            return
        }

        // Placemark for Driver's Current Location
        let driverPlacemark = MKPlacemark(coordinate: driverLocation)
        let driverMapItem = MKMapItem(placemark: driverPlacemark)
        driverMapItem.name = "Driver Location"

        // Placemark for Pickup Location
        let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: activeRide.pickupLocation.latitude,
            longitude: activeRide.pickupLocation.longitude
        ))
        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
        pickupMapItem.name = "Pickup Location"

        // Placemark for Dropoff Location
        let dropoffPlacemark = MKPlacemark(coordinate: destination)
        let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
        dropoffMapItem.name = "Dropoff Location"

        // Launch options
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ]

        // Open Apple Maps with the route
        MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
    }

    private func logout() {
        isLoggedIn = false
    }
}

// MARK: - **Fix: Ensure Three Points Show on Map**
/*extension DriverDashboardView {
    private func fetchDriverLocation() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching location: \(error.localizedDescription)"
                return
            }
            if let data = snapshot?.data(), let location = data["location"] as? GeoPoint {
                driverLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            }
        }
    }
}

// MARK: - **Fetch Available Rides**
extension DriverDashboardView {
    private func fetchAvailableRides() {
    db.collection("rides")
    .whereField("status", isEqualTo: "requested")
    .addSnapshotListener { snapshot, error in
    if let error = error {
    errorMessage = "Error fetching rides: \(error.localizedDescription)"
    return
    }
    guard let documents = snapshot?.documents else { return }
    self.availableRides = documents.map { doc in
    RideRequest(id: doc.documentID, data: doc.data())
    }
    }
    }
    }*/

  /*  private func fetchAvailableRides() {
        db.collection("rides")
            .whereField("status", isEqualTo: "requested")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Error fetching rides: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableRides = documents.map { doc in
                    RideRequest(id: doc.documentID, data: doc.data())
                }
            }
    }
}*/

 /*
  // MARK: - **Logout Button**
  extension DriverDashboardView {
  private var logoutButton: some View {
  Button(action: logout) {
  HStack {
  Image(systemName: "power.circle.fill")
  .resizable()
  .frame(width: 40, height: 40)
  .foregroundColor(.red)
  
  Text("Logout")
  .foregroundColor(.white)
  .font(.headline)
  }
  .frame(maxWidth: .infinity)
  .padding()
  }
  .background(Color.red.opacity(0.2))
  .cornerRadius(12)
  }
  private func logout() {
  isLoggedIn = false
  }
  }
  
  
  
  // MARK: - **Firebase Fetching**
  extension DriverDashboardView {
  private func fetchDriverProfile() {
  guard let userId = auth.currentUser?.uid else { return }
  
  db.collection("drivers").document(userId).getDocument { snapshot, error in
  if let error = error {
  errorMessage = "Error fetching profile: \(error.localizedDescription)"
  return
  }
  if let data = snapshot?.data(), let imageUrl = data["profileImageURL"] as? String {
  profileImageURL = imageUrl
  }
  }
  }
  private func updateFCMToken(token: String) {
  guard let userId = auth.currentUser?.uid else { return }
  db.collection("drivers").document(userId).updateData([
  "fcmToken": token
  ]) { error in
  if let error = error {
  errorMessage = "Error updating FCM token: \(error.localizedDescription)"
  }
  }
  }
  
  
  
  
  
  private func fetchDriverLocation() {
  guard let userId = Auth.auth().currentUser?.uid else { return }
  
  db.collection("drivers").document(userId).getDocument { snapshot, error in
  if let error = error {
  errorMessage = "Error fetching location: \(error.localizedDescription)"
  return
  }
  if let data = snapshot?.data(), let location = data["location"] as? GeoPoint {
  driverLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
  }
  }
  }
  
  private func fetchAvailableRides() {
  db.collection("rides")
  .whereField("status", isEqualTo: "requested")
  .addSnapshotListener { snapshot, error in
  if let error = error {
  errorMessage = "Error fetching rides: \(error.localizedDescription)"
  return
  }
  guard let documents = snapshot?.documents else { return }
  self.availableRides = documents.map { doc in
  RideRequest(id: doc.documentID, data: doc.data())
  }
  }
  }
  }
  
  // MARK: - **Earnings Section**
  extension DriverDashboardView {
  private var earningsSection: some View {
  VStack {
  Text("Earnings")
  .font(.headline)
  .foregroundColor(.white)
  Text("$\(earnings, specifier: "%.2f")")
  .font(.largeTitle)
  .fontWeight(.bold)
  .foregroundColor(.white)
  }
  .padding()
  .background(
  RoundedRectangle(cornerRadius: 15)
  .fill(Color.black.opacity(0.3))
  .shadow(radius: 5)
  )
  }
  }
  
  
  // MARK: - **Push Notifications**
  extension DriverDashboardView {
  private func setupPushNotifications() {
  Messaging.messaging().token { token, error in
  if let error = error {
  errorMessage = "Error fetching FCM token: \(error.localizedDescription)"
  return
  }
  if let token = token {
  db.collection("drivers").document("mockDriverId").updateData(["fcmToken": token])
  }
  }
  }
  
  
  }
  // MARK: - **Ride Requests & Active Ride**
  extension DriverDashboardView {
  private var availableRidesSection: some View {
  VStack {
  if availableRides.isEmpty && !isLoading {
  Text("No available rides at the moment.")
  .foregroundColor(.white.opacity(0.8))
  .font(.subheadline)
  .padding()
  } else {
  List(availableRides) { ride in
  rideCard(ride: ride)
  .listRowBackground(Color.clear)
  .transition(.opacity)
  }
  .background(Color.black.opacity(0.2))
  .cornerRadius(15)
  .padding(.horizontal)
  }
  }
  .frame(maxWidth: .infinity)
  }
  private func rideCard(ride: RideRequest) -> some View {
  VStack(alignment: .leading, spacing: 8) {
  Text("📍 Pickup: \(ride.pickupAddress ?? "Unknown")")
  .fontWeight(.bold)
  Text("🏁 Dropoff: \(ride.dropoffAddress ?? "Unknown")")
  .foregroundColor(.white.opacity(0.7))
  
  HStack {
  Button("Accept") {
  
  acceptRide(ride: ride) // replace with actual rideId
  }
  .buttonStyle(RideButtonStyle(color: .green))
  
  
  
  Button("Decline") {
  declineRide(ride: ride)
  }
  .buttonStyle(RideButtonStyle(color: .red))
  }
  }
  .padding()
  .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
  }
  
  private func acceptRide(ride: RideRequest) {
  activeRide = ride
  }
  
  private func declineRide(ride: RideRequest) {
  availableRides.removeAll { $0.id == ride.id }
  }
  // MARK: - **Custom Button Style**
  struct RideButtonStyle: ButtonStyle {
  var color: Color
  func makeBody(configuration: Configuration) -> some View {
  configuration.label
  .frame(maxWidth: .infinity)
  .padding()
  .background(color.opacity(configuration.isPressed ? 0.7 : 1))
  .foregroundColor(.white)
  .cornerRadius(10)
  .shadow(radius: 3)
  }
  }
  }
  // MARK: - **Floating Online/Offline Button**
  extension DriverDashboardView {
  private var onlineOfflineButton: some View {
  Button(action: {
  
  isOffline.toggle()
  updateDriverStatus(isOnline: !isOffline)
  }) {
  Image(systemName: isOffline ? "power.circle.fill" : "power.circle")
  .resizable()
  .frame(width: 60, height: 60)
  .foregroundColor(isOffline ? .green : .red)
  .background(Circle().fill(Color.white.opacity(0.2)))
  .shadow(radius: 5)
  }
  .padding(.bottom, 20)
  }
  
  
  
  
  private func updateDriverStatus(isOnline: Bool)  {
  db.collection("drivers").document("mockDriverId").updateData([
  "isOnline": isOnline
  ]) { error in
  if let error = error {
  errorMessage = "Failed to update driver status: \(error.localizedDescription)"
  }
  }
  }
  }
  
  /*
   import SwiftUI
   import FirebaseFirestore
   import FirebaseAuth
   import SDWebImageSwiftUI
   import MapKit
   import CoreLocation
   import FirebaseMessaging
   
   struct DriverDashboardView: View {
   @Binding var isLoggedIn: Bool
   @State private var availableRides: [RideRequest] = []
   @State private var activeRide: RideRequest?
   @State private var mapView = MKMapView()
   @State private var isOffline: Bool = false
   @State private var driverLocation: CLLocationCoordinate2D?
   @State private var isLoading: Bool = false
   @State private var errorMessage: String?
   @State private var profileImageURL: String?
   @State private var earnings: Double = 0.0
   @ObservedObject private var locationManager = LocationManager.shared
   @State private var showNavigation: Bool = false
   
   private let db = Firestore.firestore()
   private let auth = Auth.auth()
   
   @Environment(\.presentationMode) var presentationMode
   
   var body: some View {
   ZStack {
   // Background Gradient
   LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
   .ignoresSafeArea()
   
   VStack(spacing: 20) {
   // **Profile and Availability Status**
   headerSection
   
   // **Ride Details**
   if let ride = activeRide {
   activeRideView(ride: ride)
   .transition(.slide)
   } else {
   availableRidesSection
   }
   
   // **Earnings Dashboard**
   earningsSection
   
   Spacer()
   
   // **Floating Action Button for Online/Offline**
   onlineOfflineButton
   
   // **Logout Button**
   logoutButton
   }
   .padding()
   .overlay(
   isLoading ? ProgressView().scaleEffect(2) : nil
   )
   .onAppear {
   setupLocationManager()
   fetchDriverLocation()
   fetchAvailableRides()
   fetchDriverProfile()
   fetchEarnings()
   setupPushNotifications()
   }
   .alert(isPresented: .constant(errorMessage != nil)) {
   Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
   }
   .sheet(isPresented: $showNavigation) {
   if let ride = activeRide {
   NavigationView {
   Text("Navigation for \(ride.pickupAddress ?? "Pickup")")
   }
   } else {
   EmptyView() // Ensure SwiftUI always has a valid View
   }
   }
   }
   
   }
   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
   guard let location = locations.last else { return }
   driverLocation = location.coordinate
   }
   private func activeRideView(ride: RideRequest) -> some View {
   VStack {
   Text("🚖 Active Ride")
   .font(.title2)
   .bold()
   
   MapView(
   userLocation: Binding(
   get: { driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) },
   set: { driverLocation = $0 }
   ),
   destination: Binding(
   get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
   set: { _ in }
   ),
   driverLocation: Binding(
   get: { driverLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) },
   set: { driverLocation = $0 }
   ),
   mapView: $mapView
   )
   .frame(height: 250)
   .cornerRadius(10)
   
   VStack(alignment: .leading) {
   Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
   Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
   }
   .padding()
   
   Button("Start Navigation") {
   let dropoffCoordinate = CLLocationCoordinate2D(
   latitude: ride.dropoffLocation.latitude,
   longitude: ride.dropoffLocation.longitude
   )
   startNavigation(to: dropoffCoordinate)
   }
   .buttonStyle(.borderedProminent)
   }
   .padding()
   .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
   }
   private var availableRidesSection: some View {
   List(availableRides) { ride in
   VStack(alignment: .leading) {
   Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
   Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
   
   HStack {
   Button("Accept Ride") {
   acceptRide(ride: ride)
   }
   .buttonStyle(.borderedProminent)
   
   Button("Decline") {
   declineRide(ride: ride)
   }
   .buttonStyle(.bordered)
   .foregroundColor(.red)
   }
   }
   }
   }
   private var onlineOfflineButton: some View {
   Button(action: {
   isOffline.toggle()
   updateDriverStatus(isOnline: !isOffline)
   }) {
   Text(isOffline ? "Go Online" : "Go Offline")
   .frame(maxWidth: .infinity)
   .padding()
   .background(isOffline ? Color.green : Color.red)
   .foregroundColor(.white)
   .cornerRadius(10)
   }
   .padding()
   }
   private func setupLocationManager() {
   locationManager.requestAuthorization() // ✅ Fix: Call the correct function
   locationManager.startUpdatingLocation()
   }
   private func fetchDriverLocation() {
   guard let userId = Auth.auth().currentUser?.uid else { return }
   
   db.collection("drivers").document(userId).getDocument { snapshot, error in
   if let error = error {
   errorMessage = "Error fetching location: \(error.localizedDescription)"
   return
   }
   if let data = snapshot?.data(), let location = data["location"] as? GeoPoint {
   driverLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
   }
   }
   }
   
   private func fetchAvailableRides() {
   db.collection("rides")
   .whereField("status", isEqualTo: "requested")
   .addSnapshotListener { snapshot, error in
   if let error = error {
   errorMessage = "Error fetching rides: \(error.localizedDescription)"
   return
   }
   guard let documents = snapshot?.documents else { return }
   self.availableRides = documents.map { doc in
   RideRequest(id: doc.documentID, data: doc.data())
   }
   }
   }
   private func fetchEarnings() {
   guard let userId = Auth.auth().currentUser?.uid else { return }
   
   db.collection("drivers").document(userId).getDocument { snapshot, error in
   if let error = error {
   errorMessage = "Error fetching earnings: \(error.localizedDescription)"
   return
   }
   if let data = snapshot?.data(), let earnings = data["earnings"] as? Double {
   self.earnings = earnings
   }
   }
   }
   
   }
   
   // MARK: - **Header Section**
   extension DriverDashboardView {
   private var headerSection: some View {
   VStack {
   HStack {
   VStack(alignment: .leading) {
   Text("GoMoto Driver")
   .font(.title2)
   .fontWeight(.bold)
   .foregroundColor(.white)
   
   Text(isOffline ? "Offline" : "Online")
   .foregroundColor(isOffline ? .red : .green)
   .font(.subheadline)
   .bold()
   }
   Spacer()
   
   // Profile Picture (Driver Image)
   if let imageUrl = profileImageURL, !imageUrl.isEmpty {
   WebImage(url: URL(string: imageUrl))
   .resizable()
   .aspectRatio(contentMode: .fill)
   .frame(width: 50, height: 50)
   .clipShape(Circle())
   .overlay(Circle().stroke(Color.white, lineWidth: 2))
   .shadow(radius: 5)
   } else {
   Image(systemName: "person.crop.circle.fill")
   .resizable()
   .frame(width: 50, height: 50)
   .foregroundColor(.white)
   }
   }
   .padding(.horizontal)
   }
   .padding(.vertical)
   .background(
   RoundedRectangle(cornerRadius: 15)
   .fill(Color.black.opacity(0.3))
   .shadow(radius: 5)
   )
   }
   }
   
   // MARK: - **Earnings Section**
   extension DriverDashboardView {
   private var earningsSection: some View {
   VStack {
   Text("Earnings")
   .font(.headline)
   .foregroundColor(.white)
   Text("$\(earnings, specifier: "%.2f")")
   .font(.largeTitle)
   .fontWeight(.bold)
   .foregroundColor(.white)
   }
   .padding()
   .background(
   RoundedRectangle(cornerRadius: 15)
   .fill(Color.black.opacity(0.3))
   .shadow(radius: 5)
   )
   }
   }
   
   // MARK: - **Logout Button**
   extension DriverDashboardView {
   private var logoutButton: some View {
   Button(action: logout) {
   Text("Logout")
   .frame(maxWidth: .infinity)
   .padding()
   .background(Color.blue.opacity(0.9))
   .foregroundColor(.white)
   .cornerRadius(12)
   }
   .padding(.horizontal)
   }
   }
   
   // MARK: - **Fetch Driver Profile**
   extension DriverDashboardView {
   private func fetchDriverProfile() {
   guard let userId = auth.currentUser?.uid else { return }
   
   db.collection("drivers").document(userId).getDocument { snapshot, error in
   if let error = error {
   errorMessage = "Error fetching profile: \(error.localizedDescription)"
   return
   }
   if let data = snapshot?.data(), let imageUrl = data["profileImageURL"] as? String {
   profileImageURL = imageUrl
   }
   }
   }
   
   private func logout() {
   do {
   try auth.signOut()
   isLoggedIn = false
   presentationMode.wrappedValue.dismiss()
   } catch {
   errorMessage = "Failed to log out."
   }
   }
   }
   
   // MARK: - **Push Notifications**
   extension DriverDashboardView {
   private func setupPushNotifications() {
   Messaging.messaging().token { token, error in
   if let error = error {
   errorMessage = "Error fetching FCM token: \(error.localizedDescription)"
   return
   }
   if let token = token {
   updateFCMToken(token: token)
   }
   }
   }
   
   private func updateFCMToken(token: String) {
   guard let userId = auth.currentUser?.uid else { return }
   db.collection("drivers").document(userId).updateData([
   "fcmToken": token
   ]) { error in
   if let error = error {
   errorMessage = "Error updating FCM token: \(error.localizedDescription)"
   }
   }
   }
   // accept ride func
   private func acceptRide(ride: RideRequest) {
   activeRide = ride
   }
   
   private func declineRide(ride: RideRequest) {
   availableRides.removeAll { $0.id == ride.id }
   }
   
   
   func startNavigation(to destination: CLLocationCoordinate2D) {
   let destinationPlacemark = MKPlacemark(coordinate: destination)
   let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
   destinationMapItem.name = "Drop-off Location"
   
   let launchOptions: [String: Any] = [
   MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
   MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: destination)
   ]
   
   destinationMapItem.openInMaps(launchOptions: launchOptions)
   }
   private func updateDriverStatus(isOnline: Bool) {
   db.collection("drivers").document("mockDriverId").updateData([
   "isOnline": isOnline
   ]) { error in
   if let error = error {
   errorMessage = "Failed to update driver status: \(error.localizedDescription)"
   }
   }
   }
   
   
   }*/
  
  /*import SwiftUI
   import FirebaseFirestore
   import MapKit
   
   struct DriverDashboardView: View {
   @Binding var isLoggedIn: Bool
   @State private var availableRides: [RideRequest] = []
   @State private var activeRide: RideRequest?
   @State private var mapView = MKMapView()
   @State private var isOffline: Bool = false
   @State private var driverLocation: CLLocationCoordinate2D?
   @State private var isLoading: Bool = false
   @State private var errorMessage: String?
   
   private let db = Firestore.firestore()
   @Environment(\.presentationMode) var presentationMode
   
   var body: some View {
   ZStack {
   // Background Gradient
   LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
   .ignoresSafeArea()
   
   VStack(spacing: 20) {
   // **Profile and Availability Status**
   headerSection
   
   // **Ride Details**
   if let ride = activeRide {
   activeRideView(ride: ride)
   .transition(.slide)
   } else {
   availableRidesSection
   }
   
   Spacer()
   
   // **Floating Action Button for Online/Offline**
   onlineOfflineButton
   
   // **Logout Button**
   logoutButton
   }
   .padding()
   .overlay(
   isLoading ? ProgressView().scaleEffect(2) : nil
   )
   .onAppear {
   fetchDriverLocation()
   fetchAvailableRides()
   }
   }
   }
   }
   
   // MARK: - **Header Section**
   extension DriverDashboardView {
   private var headerSection: some View {
   VStack {
   HStack {
   VStack(alignment: .leading) {
   Text("GoMoto Driver")
   .font(.title2)
   .fontWeight(.bold)
   .foregroundColor(.white)
   
   Text(isOffline ? "Offline" : "Online")
   .foregroundColor(isOffline ? .red : .green)
   .font(.subheadline)
   .bold()
   }
   Spacer()
   Image(systemName: "person.crop.circle.fill")
   .resizable()
   .frame(width: 50, height: 50)
   .foregroundColor(.white)
   }
   .padding(.horizontal)
   }
   .padding(.vertical)
   .background(
   RoundedRectangle(cornerRadius: 15)
   .fill(Color.black.opacity(0.3))
   .shadow(radius: 5)
   )
   }
   }
   
   // MARK: - **Ride Requests & Active Ride**
   extension DriverDashboardView {
   private var availableRidesSection: some View {
   VStack {
   if availableRides.isEmpty && !isLoading {
   Text("No available rides at the moment.")
   .foregroundColor(.white.opacity(0.8))
   .font(.subheadline)
   .padding()
   } else {
   List(availableRides) { ride in
   rideCard(ride: ride)
   .listRowBackground(Color.clear)
   .transition(.opacity)
   }
   .background(Color.black.opacity(0.2))
   .cornerRadius(15)
   .padding(.horizontal)
   }
   }
   .frame(maxWidth: .infinity)
   }
   
   private func rideCard(ride: RideRequest) -> some View {
   VStack(alignment: .leading, spacing: 8) {
   Text("📍 Pickup: \(ride.pickupAddress ?? "Unknown")")
   .fontWeight(.bold)
   Text("🏁 Dropoff: \(ride.dropoffAddress ?? "Unknown")")
   .foregroundColor(.white.opacity(0.7))
   
   HStack {
   Button("Accept") {
   acceptRide(ride: ride)
   }
   .buttonStyle(RideButtonStyle(color: .green))
   
   Button("Decline") {
   declineRide(ride: ride)
   }
   .buttonStyle(RideButtonStyle(color: .red))
   }
   }
   .padding()
   .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
   }
   
   private func activeRideView(ride: RideRequest) -> some View {
   VStack(spacing: 10) {
   Text("🚖 Active Ride")
   .font(.title2)
   .bold()
   .foregroundColor(.white)
   
   // **Map with Route**
   MapView(
   userLocation: Binding(
   get: { CLLocationCoordinate2D(latitude: ride.pickupLocation.latitude, longitude: ride.pickupLocation.longitude) },
   set: { _ in }
   ),
   destination: Binding(
   get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
   set: { _ in }
   ),
   driverLocation: Binding(
   get: { driverLocation },
   set: { driverLocation = $0 }
   ),
   mapView: $mapView
   )
   .frame(height: 300)
   .cornerRadius(12)
   
   Button("Start Navigation") {
   startNavigation(to: CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude))
   }
   .buttonStyle(RideButtonStyle(color: .blue))
   }
   .padding()
   .background(RoundedRectangle(cornerRadius: 15).fill(Color.black.opacity(0.3)))
   }
   }
   
   // MARK: - **Floating Online/Offline Button**
   extension DriverDashboardView {
   private var onlineOfflineButton: some View {
   Button(action: {
   isOffline.toggle()
   updateDriverStatus(isOnline: !isOffline)
   }) {
   Image(systemName: isOffline ? "power.circle.fill" : "power.circle")
   .resizable()
   .frame(width: 60, height: 60)
   .foregroundColor(isOffline ? .green : .red)
   .background(Circle().fill(Color.white.opacity(0.2)))
   .shadow(radius: 5)
   }
   .padding(.bottom, 20)
   }
   }
   
   // MARK: - **Logout Button**
   extension DriverDashboardView {
   private var logoutButton: some View {
   Button(action: logout) {
   Text("Logout")
   .frame(maxWidth: .infinity)
   .padding()
   .background(Color.blue.opacity(0.9))
   .foregroundColor(.white)
   .cornerRadius(12)
   }
   .padding(.horizontal)
   }
   }
   
   // MARK: - **Custom Button Style**
   struct RideButtonStyle: ButtonStyle {
   var color: Color
   func makeBody(configuration: Configuration) -> some View {
   configuration.label
   .frame(maxWidth: .infinity)
   .padding()
   .background(color.opacity(configuration.isPressed ? 0.7 : 1))
   .foregroundColor(.white)
   .cornerRadius(10)
   .shadow(radius: 3)
   }
   }
   
   // MARK: - **Functions**
   extension DriverDashboardView {
   private func fetchDriverLocation() {
   driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
   }
   
   private func fetchAvailableRides() {
   isLoading = true
   db.collection("rides").whereField("status", isEqualTo: "requested").addSnapshotListener { snapshot, error in
   isLoading = false
   guard let documents = snapshot?.documents else { return }
   self.availableRides = documents.map { RideRequest(id: $0.documentID, data: $0.data()) }
   }
   }
   
   private func acceptRide(ride: RideRequest) {
   activeRide = ride
   }
   
   private func declineRide(ride: RideRequest) {
   availableRides.removeAll { $0.id == ride.id }
   }
   
   private func logout() {
   isLoggedIn = false
   }
   private func startNavigation(to destination: CLLocationCoordinate2D) {
   guard let driverLocation = driverLocation else {
   print("Driver location is missing.")
   return
   }
   
   guard let activeRide = activeRide else {
   print("Active ride is missing.")
   return
   }
   
   // Placemark for Driver's Current Location
   let driverPlacemark = MKPlacemark(coordinate: driverLocation)
   let driverMapItem = MKMapItem(placemark: driverPlacemark)
   driverMapItem.name = "Driver Location"
   
   // Placemark for Pickup Location
   let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
   latitude: activeRide.pickupLocation.latitude,
   longitude: activeRide.pickupLocation.longitude
   ))
   let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
   pickupMapItem.name = "Pickup Location"
   
   // Placemark for Dropoff Location
   let dropoffPlacemark = MKPlacemark(coordinate: destination)
   let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
   dropoffMapItem.name = "Dropoff Location"
   
   // Launch options
   let launchOptions: [String: Any] = [
   MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
   MKLaunchOptionsShowsTrafficKey: true
   ]
   
   // Open Apple Maps with the route
   MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
   }
   private func updateDriverStatus(isOnline: Bool) {
   db.collection("drivers").document("mockDriverId").updateData([
   "isOnline": isOnline
   ]) { error in
   if let error = error {
   errorMessage = "Failed to update driver status: \(error.localizedDescription)"
   }
   }
   }
   
   }*/
  
  
   import SwiftUI
   import FirebaseFirestore
   import MapKit
   
   struct DriverDashboardView: View {
   @Binding var isLoggedIn: Bool
   @State private var availableRides: [RideRequest] = []
   @State private var activeRide: RideRequest? // Currently accepted ride
   @State private var mapView = MKMapView()
   @State private var isOffline: Bool = false // Track online/offline status
   @State private var driverLocation: CLLocationCoordinate2D?
   @State private var isLoading: Bool = false
   @State private var errorMessage: String?
   
   private let db = Firestore.firestore()
   @Environment(\.presentationMode) var presentationMode // For Back Button
   
   var body: some View {
   NavigationView {
   VStack(spacing: 20) {
   // Offline Status Indicator
   if isOffline {
   Text("You are currently offline")
   .foregroundColor(.red)
   .font(.subheadline)
   }
   
   // Active Ride or Available Rides
   if let ride = activeRide {
   activeRideView(ride: ride)
   } else if availableRides.isEmpty && !isLoading {
   noAvailableRidesView
   } else {
   availableRidesListView
   }
   
   Spacer()
   
   // Online/Offline Toggle
   toggleAvailabilityButton
   
   // Logout Button
   logoutButton
   }
   .onAppear {
   fetchDriverLocation()
   fetchAvailableRides()
   }
   .navigationTitle("Driver Dashboard")
   .overlay(
   isLoading ? ProgressView().scaleEffect(2) : nil
   )
   .alert(isPresented: .constant(errorMessage != nil), content: {
   Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
   })
   }
   }
   }
   
   // MARK: - Subviews
   extension DriverDashboardView {
   private var noAvailableRidesView: some View {
   Text("No available rides.")
   .foregroundColor(.gray)
   }
   
   private var availableRidesListView: some View {
   List(availableRides) { ride in
   VStack(alignment: .leading, spacing: 5) {
   Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
   Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
   
   HStack {
   Button("Accept Ride") {
   acceptRide(ride: ride)
   }
   .buttonStyle(.borderedProminent)
   
   Button("Decline Ride") {
   declineRide(ride: ride)
   }
   .buttonStyle(.bordered)
   .foregroundColor(.red)
   }
   }
   }
   }
   
   private var toggleAvailabilityButton: some View {
   Button(action: {
   isOffline.toggle()
   updateDriverStatus(isOnline: !isOffline)
   }) {
   Text(isOffline ? "Go Online" : "Go Offline")
   .frame(maxWidth: .infinity)
   .padding()
   .background(isOffline ? Color.green : Color.red)
   .foregroundColor(.white)
   .cornerRadius(10)
   }
   .padding()
   }
   
   private var logoutButton: some View {
   Button(action: logout) {
   Text("Logout")
   .frame(maxWidth: .infinity)
   .padding()
   .background(Color.blue)
   .foregroundColor(.white)
   .cornerRadius(10)
   }
   .padding()
   }
   
   private func activeRideView(ride: RideRequest) -> some View {
   VStack(spacing: 10) {
   Text("Active Ride").font(.headline)
   
   // MapView
   MapView(
   userLocation: Binding(
   get: { CLLocationCoordinate2D(latitude: ride.pickupLocation.latitude, longitude: ride.pickupLocation.longitude) },
   set: { _ in }
   ),
   destination: Binding(
   get: { CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude) },
   set: { _ in }
   ),
   driverLocation: Binding(
   get: { driverLocation },
   set: { driverLocation = $0 }
   ),
   mapView: $mapView
   )
   .frame(height: 300)
   .cornerRadius(10)
   
   VStack(alignment: .leading, spacing: 8) {
   Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
   Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
   }
   
   Button("Start Navigation") {
   startNavigation(to: CLLocationCoordinate2D(latitude: ride.dropoffLocation.latitude, longitude: ride.dropoffLocation.longitude))
   }
   .buttonStyle(.borderedProminent)
   }
   }
   }
   
   // MARK: - Functions
   extension DriverDashboardView {
   private func fetchDriverLocation() {
   // Mock driver location (replace with actual location updates from a LocationManager)
   driverLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
   }
   
   private func fetchAvailableRides() {
   isLoading = true
   db.collection("rides")
   .whereField("status", isEqualTo: "requested")
   .addSnapshotListener { snapshot, error in
   isLoading = false
   if let error = error {
   errorMessage = "Error fetching rides: \(error.localizedDescription)"
   return
   }
   guard let documents = snapshot?.documents else { return }
   self.availableRides = documents.map { doc in
   RideRequest(
   id: doc.documentID,
   data: doc.data()
   )
   }
   }
   }
   
   private func acceptRide(ride: RideRequest) {
   db.collection("rides").document(ride.id).updateData([
   "status": "accepted",
   "driverId": "mockDriverId" // Replace with the actual driver ID
   ]) { error in
   if let error = error {
   errorMessage = "Error accepting ride: \(error.localizedDescription)"
   return
   }
   activeRide = ride
   }
   }
   
   private func declineRide(ride: RideRequest) {
   db.collection("rides").document(ride.id).updateData([
   "status": "declined"
   ]) { error in
   if let error = error {
   errorMessage = "Error declining ride: \(error.localizedDescription)"
   return
   }
   availableRides.removeAll { $0.id == ride.id }
   }
   }
   
   private func updateDriverStatus(isOnline: Bool) {
   db.collection("drivers").document("mockDriverId").updateData([
   "isOnline": isOnline
   ]) { error in
   if let error = error {
   errorMessage = "Failed to update driver status: \(error.localizedDescription)"
   }
   }
   }
   
   private func startNavigation(to destination: CLLocationCoordinate2D) {
   guard let driverLocation = driverLocation else {
   print("Driver location is missing.")
   return
   }
   
   guard let activeRide = activeRide else {
   print("Active ride is missing.")
   return
   }
   
   // Placemark for Driver's Current Location
   let driverPlacemark = MKPlacemark(coordinate: driverLocation)
   let driverMapItem = MKMapItem(placemark: driverPlacemark)
   driverMapItem.name = "Driver Location"
   
   // Placemark for Pickup Location
   let pickupPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
   latitude: activeRide.pickupLocation.latitude,
   longitude: activeRide.pickupLocation.longitude
   ))
   let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
   pickupMapItem.name = "Pickup Location"
   
   // Placemark for Dropoff Location
   let dropoffPlacemark = MKPlacemark(coordinate: destination)
   let dropoffMapItem = MKMapItem(placemark: dropoffPlacemark)
   dropoffMapItem.name = "Dropoff Location"
   
   // Launch options
   let launchOptions: [String: Any] = [
   MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
   MKLaunchOptionsShowsTrafficKey: true
   ]
   
   // Open Apple Maps with the route
   MKMapItem.openMaps(with: [driverMapItem, pickupMapItem, dropoffMapItem], launchOptions: launchOptions)
   }
   
   private func logout() {
   isLoggedIn = false
   }
   }
  */*/*/
