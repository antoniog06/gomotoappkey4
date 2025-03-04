//
//  AnsweringView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/8/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct AnsweringView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableRides: [RideRequest] = []
    @State private var activeRide: RideRequest?
    @State private var isOffline: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var mapView = MKMapView()
    @State private var profileImageURL: String?
    @State private var driverLocation: CLLocationCoordinate2D?
    @State private var showEarningsBreakdown: Bool = false
    @State private var showVehicleInfo: Bool = false
    @State private var earnings: DriverEarnings.Metrics = DriverEarnings.Metrics(totalEarnings: 0.0, completedRides: 0, bonuses: 0.0, unreadMessages: 0)
    
    @State private var licensePlate: String = ""
    @State private var vehicleModel: String = ""
    @State private var vehicleColor: String = ""
    @State private var year: String = ""
    @State private var baseRateMultiplier: Double = 0.0
    @State private var surgePricing: Double = 0.0
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var color: String = ""
    @State private var  vehicleMake: String = ""
    @State private var emergencyTimer: Timer?
    @State private var isEmergencyActive: Bool = false
    @State private var eta: String = "Calculating..."
    @State private var driverEarnings: Double = 0.0
    @State private var completedRides: Int = 0
 //   @ObservedObject var viewModel = EarningsViewModel()
    var driverId: String
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    var body: some View {
        ZStack {
            PulsatingGradientBackground()
                .ignoresSafeArea()
            
            ScrollView {
              
                
                VStack(spacing: 16) {
                    driverStatusHeader
                        .modifier(FloatingCardEffect())
                    
                  //  EarningsSummaryView(viewModel: viewModel, driverId: driverId)
                    earningsDashboard
                        .modifier(ChartElevationEffect())
                    
                    Spacer()
                
                    actionPanel
                        .modifier(ButtonStackEffect())
                    
                    Button(action: {
                        showVehicleInfo.toggle()
                    }) {
                        Text("Edit Vehicle Info")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .overlay(loadingOverlay)
        .sheet(isPresented: $showEarningsBreakdown) {
            EarningsAnalyticsView(earnings: $earnings)
        }
        .sheet(isPresented: $showVehicleInfo) {
            VehicleInfoView(
                make: $make,
                model: $model,
                year: $year,
                licensePlate: $licensePlate,
                color: $color,
                baseRateMultiplier: $baseRateMultiplier,
                surgePricing: $surgePricing
            )
        }
        .onAppear(perform: initializeDashboard)
        .onAppear {
            initializeDashboard()
            fetchDriverStatus()
            fetchDriverEarningsAndRides()
          
               
        }
    }
}


// MARK: - Driver Status & Vehicle Info
extension AnsweringView {
    private var driverStatusHeader: some View {
        VStack(spacing: 8) {
            HStack {
                DriverProfileView( licensePlate: $licensePlate, model: $model, make: $make, year: $year, color: $color, imageUrl: profileImageURL, isOffline: $isOffline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("GoMoto Pro Driver")
                        .font(.title3)
                        .bold()
                    
                    OnlineStatusIndicator(isOnline: !isOffline)
              
               
                }
                Spacer()
            }
            .padding()
            .background(VisualEffectView(effect: .systemUltraThinMaterial))
            .cornerRadius(20)
        }
    }
}



   


// MARK: - Earnings Dashboard
extension AnsweringView {
    private var earningsDashboard: some View {
        VStack {
            HStack {
                Text("Earnings: $\(String(format: "%.2f", driverEarnings))")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("Completed Rides: \(completedRides)")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding()
            
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.2)))
            .shadow(radius: 5)
        }
        .onTapGesture { showEarningsBreakdown.toggle() }
        .onAppear {
            fetchDriverEarningsAndRides()
        }
    }
}

// MARK: - Supporting Methods
extension AnsweringView {
    private func initializeDashboard() {
        fetchDriverProfile()
        fetchAvailableRides()
    }
    
    private func fetchDriverProfile() {
        guard let driverId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        
        // Fetch the driver's profile information
        db.collection("drivers").document(driverId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching driver profile: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No driver data found for user \(driverId)")
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageURL = data["profileImageURL"] as? String ?? ""
                self.earnings = DriverEarnings.Metrics(
                    totalEarnings: data["totalEarnings"] as? Double ?? 0.0,
                    completedRides: data["completedRides"] as? Int ?? 0,
                    bonuses: data["bonuses"] as? Double ?? 0.0,
                    unreadMessages: data["unreadMessages"] as? Int ?? 0
                )
            }
        }
        
        // Fetch the vehicle information
        
        db.collection("drivers").document(driverId).collection("vehicles").document("vehicleInfo").getDocument { snapshot, error in
            if let error = error {
                print("Error fetching vehicle info: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No vehicle data found for driver \(driverId)")
                return
            }
            
            DispatchQueue.main.async {
                self.licensePlate = data["licensePlate"] as? String ?? "Unknown"
                self.make = data["make"] as? String ?? data["vehicleMake"] as? String ?? "Unknown"  // Check for both 'make' and 'vehicleMake'
                self.model = data["model"] as? String ?? data["vehicleModel"] as? String ?? "Unknown"  // Check for both 'model' and 'vehicleModel'
                self.year = data["year"] as? String ?? "Unknown"
                self.color = data["color"] as? String ?? data["vehicleColor"] as? String ?? "Unknown"  // Check for both 'color' and 'vehicleColor'
            }
        }
        
        
    }
    private func fetchDriverEarningsAndRides() {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        
        let driverRef = Firestore.firestore().collection("drivers").document(driverId)
        
        driverRef.addSnapshotListener { document, error in
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    self.driverEarnings = document.data()?["earnings"] as? Double ?? 0.0
                    self.completedRides = document.data()?["completedRides"] as? Int ?? 0
                    self.showEarningsBreakdown = true // ✅ Ensure UI updates when earnings change
                }
            } else if let error = error {
                print("Error fetching driver earnings: \(error.localizedDescription)")
            }
        }
    }
    private func calculateFare(distance: Double) -> Double {
        let baseFare = 5.0
        let perMileRate = 2.0
        let totalFare = (baseFare + (distance * perMileRate)) * surgePricing * baseRateMultiplier
        return totalFare
    }
    
    private func fetchAvailableRides() {
        db.collection("rides").whereField("status", isEqualTo: "requested").addSnapshotListener { snapshot, error in
            if let documents = snapshot?.documents {
                self.availableRides = documents.map { RideRequest(id: $0.documentID, data: $0.data()) }
            }
        }
    }
    
    private var currentUserId: String {
        auth.currentUser?.uid ?? ""
    }
    
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView("Loading...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(radius: 10)
                }
            }
        }
    }
   
   
    private var actionPanel: some View {
        HStack(spacing: 10) {
            Button(action: toggleOnlineStatus) {
                Text(isOffline ? "Go Online" : "Go Offline")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isOffline ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: otherAction) {
                Text("🔧 Other Action")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
   

    func calculateETA() {
        // Example: Assume 40km/h speed and calculate arrival time
        let distance = 10.0 // Replace with actual distance in km
        let speed = 40.0 // Example speed in km/h
        let estimatedTime = distance / speed * 60 // in minutes
        
        DispatchQueue.main.async {
            self.eta = "\(Int(estimatedTime)) min"
        }
    }
    
    private func toggleOnlineStatus() {
        guard let driverId = Auth.auth().currentUser?.uid else {
            print("Driver not authenticated")
            return
        }
        
        // Toggle the local state
        isOffline.toggle()
        
        // Update the Firestore document
        let db = Firestore.firestore()
        db.collection("drivers").document(driverId).updateData([
            "isOnline": !isOffline
        ]) { error in
            if let error = error {
                print("Error updating online status: \(error.localizedDescription)")
                // Revert the toggle if there was an error
                isOffline.toggle()
            } else {
                print("Driver is now \(isOffline ? "Offline" : "Online")")
            }
        }
    }
    private func otherAction() {
        fetchAvailableRides()
        print("Available rides refreshed!")
    }
    private func fetchDriverStatus() {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("drivers").document(driverId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching driver status: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), let onlineStatus = data["isOnline"] as? Bool {
                DispatchQueue.main.async {
                    self.isOffline = !onlineStatus
                }
                
            }
            
        }
    }
    
   
    
   
   
   
  
    
    // trigger emergency func
    // MARK: - Emergency Protocol Function
    
 

   

    // MARK: - Emergency Protocol Function
    private func triggerEmergencyProtocol() {
        guard let currentLocation = driverLocation else {
            print("Driver location unavailable for emergency.")
            return
        }
        
        sendLocationToEmergencyContact(currentLocation)

        // ✅ Use DispatchQueue.main.async to update @State variables
        DispatchQueue.main.async {
            self.emergencyTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                sendLocationToEmergencyContact(currentLocation)
            }
        }
        
        print("Emergency protocol triggered. Location shared with emergency contact.")
    }

    private func stopEmergencyProtocol() {
        // ✅ Use DispatchQueue.main.async to update @State variables
        DispatchQueue.main.async {
            self.emergencyTimer?.invalidate()
            self.emergencyTimer = nil
        }
        
        print("Emergency protocol stopped.")
    }

    // Send location to emergency contact (Dummy function)
    private func sendLocationToEmergencyContact(_ location: CLLocationCoordinate2D) {
        print("Location sent: \(location.latitude), \(location.longitude)")
    }
    
    
    
    
 
    private func getETA(to destination: CLLocationCoordinate2D, completion: @escaping (TimeInterval?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: driverLocation!))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        MKDirections(request: request).calculateETA { response, error in
            if let error = error {
                print("Error fetching ETA: \(error.localizedDescription)")
                
                completion(nil)
                return
            }
            completion(response?.expectedTravelTime)
            
        }
        
    }
    func formatETA(_ eta: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: eta) ?? "N/A"
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
import Combine

struct AnsweringView: View {
    
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
    @State private var showVehicleInfo: Bool = false
    @State private var isDriver: Bool? = nil
    @State private var earnings: DriverEarnings.Metrics = DriverEarnings.Metrics(totalEarnings: 0.0, completedRides: 0, bonuses: 0.0, unreadMessages: 0)
    
    @State private var licensePlate: String = "Unknown"
    @State private var vehicleModel: String = "Unknown"
    @State private var vehicleColor: String = "Unknown"
    @State private var year: String = "Unknown"
    
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0
    @State private var isSurgeEnabled: Bool = false
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            PulsatingGradientBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    driverStatusHeader
                        .modifier(FloatingCardEffect())
                    
                    // Active ride or ride opportunities
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
                    
                    // Button to open Vehicle Info Sheet
                    Button(action: {
                        showVehicleInfo.toggle()
                    }) {
                        Text("Edit Vehicle Info")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .overlay(loadingOverlay)
        .alert(errorMessage ?? "", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {}
            .sheet(isPresented: $showEarningsBreakdown) {
                EarningsAnalyticsView(earnings: $earnings)
                    .transition(.move(edge: .bottom))
            }
            .sheet(isPresented: $showVehicleInfo) {
                VehicleInfoView(
                    make: $vehicleModel,
                    model: $vehicleModel,
                    year: $year,
                    licensePlate: $licensePlate,
                    color: $vehicleColor,
                    baseRateMultiplier: $baseRateMultiplier,
                    surgePricing: $surgePricing
                )
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
extension AnsweringView {
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
 
    
    
    private func fetchDriverProfile() {
        guard let driverId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        
        // Fetch the driver's profile information
        db.collection("drivers").document(driverId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching driver profile: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No driver data found for user \(driverId)")
                return
            }
            
            // Update profile data
            DispatchQueue.main.async {
                self.profileImageURL = data["profileImageURL"] as? String ?? ""
                self.earnings = DriverEarnings.Metrics(
                    totalEarnings: data["totalEarnings"] as? Double ?? 0.0,
                    completedRides: data["completedRides"] as? Int ?? 0,
                    bonuses: data["bonuses"] as? Double ?? 0.0,
                    unreadMessages: data["unreadMessages"] as? Int ?? 0
                )
            }
        }
        
        // Fetch the vehicle information under the driver's document
        db.collection("drivers").document(driverId).collection("vehicles").document("vehicleInfo").getDocument { snapshot, error in
            if let error = error {
                print("Error fetching vehicle info: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No vehicle data found for driver \(driverId)")
                return
            }
            
            // Update vehicle-related data
            DispatchQueue.main.async {
                self.licensePlate = data["licensePlate"] as? String ?? "Unknown"
                self.vehicleModel = data["model"] as? String ?? "Unknown"
                self.vehicleColor = data["color"] as? String ?? "Unknown"
                self.baseRateMultiplier = data["baseRateMultiplier"] as? Double ?? 1.0
                self.isSurgeEnabled = data["isSurgeEnabled"] as? Bool ?? false
                self.surgePricing = data["surgePricing"] as? Double ?? 1.0
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
extension AnsweringView {
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
extension AnsweringView {
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
extension AnsweringView {
    
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
    func checkUserRole() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Check if user is a driver
        db.collection("drivers").document(userId).getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // User is a driver
                isDriver = true
            } else {
                // Not a driver, check if user is a regular user
                db.collection("users").document(userId).getDocument { snapshot, error in
                    if let snapshot = snapshot, snapshot.exists {
                        // User is a regular user
                        isDriver = false
                    } else {
                        print("No role found for user")
                    }
                }
            }
        }
    }
  
}
 */

/*
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct AnsweringView: View {

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
    @State private var earnings: DriverEarnings.Metrics = DriverEarnings.Metrics(totalEarnings: 0.0, completedRides: 0, bonuses: 0.0, unreadMessages: 0)
    @State private var driver: Driver?
    @State private var licensePlate: String = "Unknown"
    @State private var vehicleModel: String = "Unknown"
    @State private var vehicleColor: String = "Unknown"
    @State private var showVehicleInfo: Bool = false
    @State private var year: String = "Unknown"
    @State private var isDriver: Bool? = nil

    // **Dynamic Pricing Controls**
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0
    @State private var isSurgeEnabled: Bool = false
    @State private var preferredRouteType: RouteType = .fastest

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            PulsatingGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        if let role = isDriver {
                            if role {
                                DriverDashboardView(isLoggedIn: $isLoggedIn)
                            } else {
                                UserDashboardView(isLoggedIn: $isLoggedIn)
                            }
                        } else {
                            ProgressView("Checking Role ...")
                                .onAppear(perform: checkUserRole)
                        }
                    }

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

                    actionPanel
                        .modifier(ButtonStackEffect())

                    // Button to trigger Vehicle Info Sheet
                    Button(action: {
                        showVehicleInfo.toggle()
                    }) {
                        Text("Edit Vehicle Info")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 20) // Add space at the bottom
                }
                .padding(.horizontal)
            }
        }
        .overlay(loadingOverlay)
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showEarningsBreakdown) {
            EarningsAnalyticsView(earnings: $earnings)
                .transition(.move(edge: .bottom))
        }
        .onAppear(perform: initializeDashboard)
        .onReceive(locationManager.$driverLocation) { location in
            if let coordinate = location {
                let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                handleLocationUpdate(clLocation)
            }
        }
        .sheet(isPresented: $showVehicleInfo) {
            VehicleInfoView(
                make: $vehicleModel,
                model: $vehicleModel,
                year: $year,
                licensePlate: $licensePlate,
                color: $vehicleColor,
                baseRateMultiplier: $baseRateMultiplier,
                surgePricing: $surgePricing
            )
        }
    }
}*/

/*
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct AnsweringView: View {
    
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
    @State private var showVehicleInfo: Bool = false
    @State private var year: String = "Unknown"
    @State private var isDriver: Bool? = nil
    
    // **Dynamic Pricing Controls**
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0
    @State private var isSurgeEnabled: Bool = false
    @State private var preferredRouteType: RouteType = .fastest
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Group {
                if let role = isDriver {
                    if role {
                        DriverDashboardView(isLoggedIn: $isLoggedIn)
                    } else {
                        UserDashboardView(isLoggedIn: $isLoggedIn)
                    }
                    else {
                        ProgressView("Checking Role ...")
                            .onAppear(perform: checkUserRole )
                    }
                }
            
        
                                      }
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
       
                    // Your UI here...

                    // Presenting Vehicle Info Sheet
       .sheet(isPresented: $showVehicleInfo) {
            VehicleInfoView(
                make: $vehicleModel,
                model: $vehicleModel,
                year: $year,
                licensePlate: $licensePlate,
                color: $vehicleColor,
                baseRateMultiplier: $baseRateMultiplier,
                surgePricing: $surgePricing
                
            )
        }

                    // Button to trigger the sheet
                    Button(action: {
                        showVehicleInfo.toggle()
                    }) {
                        Text("Edit Vehicle Info")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
        

*/

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
/*private func activeRideView(ride: RideRequest) -> some View {
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
/*
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct AnsweringView: View {

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
    @State private var earnings: DriverEarnings.Metrics = DriverEarnings.Metrics(totalEarnings: 0.0, completedRides: 0, bonuses: 0.0, unreadMessages: 0)
    @State private var driver: Driver?
    @State private var licensePlate: String = "Unknown"
    @State private var vehicleModel: String = "Unknown"
    @State private var vehicleColor: String = "Unknown"
    @State private var showVehicleInfo: Bool = false
    @State private var year: String = "Unknown"
    @State private var isDriver: Bool? = nil

    // **Dynamic Pricing Controls**
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0
    @State private var isSurgeEnabled: Bool = false
    @State private var preferredRouteType: RouteType = .fastest

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            PulsatingGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        if let role = isDriver {
                            if role {
                                DriverDashboardView(isLoggedIn: $isLoggedIn)
                            } else {
                                UserDashboardView(isLoggedIn: $isLoggedIn)
                            }
                        } else {
                            ProgressView("Checking Role ...")
                                .onAppear(perform: checkUserRole)
                        }
                    }

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

                    actionPanel
                        .modifier(ButtonStackEffect())

                    // Button to trigger Vehicle Info Sheet
                    Button(action: {
                        showVehicleInfo.toggle()
                    }) {
                        Text("Edit Vehicle Info")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 20) // Add space at the bottom
                }
                .padding(.horizontal)
            }
        }
        .overlay(loadingOverlay)
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showEarningsBreakdown) {
            EarningsAnalyticsView(earnings: $earnings)
                .transition(.move(edge: .bottom))
        }
        .onAppear(perform: initializeDashboard)
        .onReceive(locationManager.$driverLocation) { location in
            if let coordinate = location {
                let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                handleLocationUpdate(clLocation)
            }
        }
        .sheet(isPresented: $showVehicleInfo) {
            VehicleInfoView(
                make: $vehicleModel,
                model: $vehicleModel,
                year: $year,
                licensePlate: $licensePlate,
                color: $vehicleColor,
                baseRateMultiplier: $baseRateMultiplier,
                surgePricing: $surgePricing
            )
        }
    }
}*/

/*
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI
import MapKit
import CoreLocation
import FirebaseMessaging
import Combine

struct AnsweringView: View {
    
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
    @State private var showVehicleInfo: Bool = false
    @State private var year: String = "Unknown"
    @State private var isDriver: Bool? = nil
    
    // **Dynamic Pricing Controls**
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Double = 1.0
    @State private var isSurgeEnabled: Bool = false
    @State private var preferredRouteType: RouteType = .fastest
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Group {
                if let role = isDriver {
                    if role {
                        DriverDashboardView(isLoggedIn: $isLoggedIn)
                    } else {
                        UserDashboardView(isLoggedIn: $isLoggedIn)
                    }
                    else {
                        ProgressView("Checking Role ...")
                            .onAppear(perform: checkUserRole )
                    }
                }
            
        
                                      }
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
       
                    // Your UI here...

                    // Presenting Vehicle Info Sheet
       .sheet(isPresented: $showVehicleInfo) {
            VehicleInfoView(
                make: $vehicleModel,
                model: $vehicleModel,
                year: $year,
                licensePlate: $licensePlate,
                color: $vehicleColor,
                baseRateMultiplier: $baseRateMultiplier,
                surgePricing: $surgePricing
                
            )
        }

                    // Button to trigger the sheet
                    Button(action: {
                        showVehicleInfo.toggle()
                    }) {
                        Text("Edit Vehicle Info")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
        

*/
