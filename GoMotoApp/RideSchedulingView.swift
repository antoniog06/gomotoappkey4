


import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct RideSchedulingView: View {
    @State private var annotations: [AnnotatedLocation] = []
    @State private var driverLocation: CLLocationCoordinate2D? = nil
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var destinationLocation: CLLocationCoordinate2D? = nil
    @State private var routePolyline: MKPolyline? = nil
    @State private var userRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var rideId: String = ""
    @State private var statusMessage: String = ""
    @State private var isScheduling: Bool = false
    @State private var isRideFetched: Bool = false
    @StateObject private var locationManager = LocationManager.shared
    private let rideService = FirestoreRideService()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pickup Location Input
                    HStack {
                        TextField("Pickup Location", text: $pickupLocation)
                            .onTapGesture {
                                dismissKeyboard() // ensure old interactions are stopped
                                DispatchQueue.main.async {
                                    self.pickupLocation = "Updated Address"
                                }
                            }
                            .onChange(of: pickupLocation) { newValue in
                                geocodeAddressString(newValue) { location in
                                    if let location = location {
                                        userLocation = location
                                        userRegion.center = location
                                        print("Pickup Location Set: \(location)")
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        Button(action: fetchUserLocation) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    // Drop-off Location Input
                    TextField("Drop-off Location", text: $dropoffLocation)
                        .onChange(of: dropoffLocation) { newValue in
                            geocodeAddressString(newValue) { location in
                                if let location = location {
                                    destinationLocation = location
                                    print("Drop-off Location Set: \(location)")
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: scheduleRide) {
                            Text("Schedule Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isScheduling)

                        Button(action: fetchRide) {
                            Text("Fetch Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        if isRideFetched {
                            Button(action: cancelRide) {
                                Text("Cancel Ride")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Map View with Annotations and Route Overlay
                    Map(coordinateRegion: $userRegion, annotationItems: getAnnotations()) { location in
                        MapAnnotation(coordinate: location.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(location.label == "Driver Location" ? .green : .blue)
                                    .font(.title)
                                Text(location.label)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()

                    // Status Message
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .navigationTitle("Ride Scheduling")
                .onAppear {
                    setupLocationManager()
                    listenForDriverUpdates()
                }
               
            }
            
        }
        
    }
   

    struct AnnotatedLocation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let label: String
    }

    // MARK: - Functions
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    // MARK: - Firebase Listener
    private func listenForDriverUpdates() {
        rideService.listenForDriverLocation { location in
            self.driverLocation = location
            updateRoute()
        }
    }
    private func setupLocationManager() {
        locationManager.requestAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func fetchUserLocation() {
        guard let location = locationManager.currentLocation else {
            statusMessage = "Unable to fetch user location."
            return
        }
        userLocation = location.coordinate
        userRegion.center = location.coordinate

        fetchAddress(from: location.coordinate) { address in
            pickupLocation = address ?? "Failed to fetch address"
        }
    }
    private func fetchRide() {
        guard !rideId.isEmpty else {
            statusMessage = "Please enter a ride ID to fetch."
            return
        }

        rideService.fetchRide(rideId: rideId) { result in
            switch result {
            case .success(let data):
                statusMessage = "Ride data: \(data)"
                isRideFetched = true
            case .failure(let error):
                statusMessage = "Error fetching ride: \(error.localizedDescription)"
                isRideFetched = false
            }
        }
    }

    private func cancelRide() {
        guard !rideId.isEmpty else {
            statusMessage = "Please enter a ride ID to cancel."
            return
        }

        rideService.updateRideStatus(rideId: rideId, newStatus: "cancelled") { result in
            switch result {
            case .success:
                statusMessage = "Ride cancelled successfully."
                isRideFetched = false
            case .failure(let error):
                statusMessage = "Error cancelling ride: \(error.localizedDescription)"
            }
        }
    }

   
    // update ride func
    // MARK: - Route Drawing
    private func updateRoute() {
        guard let driverLocation = driverLocation else { return }

        let source = MKMapItem(placemark: MKPlacemark(coordinate: driverLocation))
        let destinationCoordinate = userLocation ?? destinationLocation
        guard let destinationCoordinate = destinationCoordinate else { return }

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                statusMessage = "Error calculating route: \(error.localizedDescription)"
                return
            }

            if let route = response?.routes.first {
                self.routePolyline = route.polyline
                self.userRegion = MKCoordinateRegion(route.polyline.boundingMapRect)
            }
        }
    }

    private func fetchAddress(from location: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let locationObj = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(locationObj) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.postalCode]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                completion(address)
            } else {
                completion(nil)
            }
        }
    }

    private func geocodeAddressString(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(nil)
                return
            }
            completion(location.coordinate)
        }
    }

    private func getAnnotations() -> [AnnotatedLocation] {
        var annotations: [AnnotatedLocation] = []

        if let userLocation = userLocation {
            annotations.append(AnnotatedLocation(coordinate: userLocation, label: "Pickup Location"))
        }
        if let destination = destinationLocation {
            annotations.append(AnnotatedLocation(coordinate: destination, label: "Drop-off Location"))
        }
        if let driver = driverLocation {
            annotations.append(AnnotatedLocation(coordinate: driver, label: "Driver Location"))
        }

        return annotations
    }

    private func scheduleRide() {
        print("Schedule Ride Button Tapped")

        guard let userId = Auth.auth().currentUser?.uid else {
            statusMessage = "User not logged in."
            return
        }

        guard let userLoc = userLocation, let destLoc = destinationLocation else {
            statusMessage = "Pickup and dropoff locations are required."
            return
        }

        let distance = calculateDistance(from: userLoc, to: destLoc)
        let fareAmount = calculateEstimatedFare(distance: distance)
        let estimatedTime = calculateEstimatedTime(distance: distance)

        let rideData: [String: Any] = [
            "passengerId": userId,
            "passengerName": Auth.auth().currentUser?.displayName ?? "Anonymous",
            "pickupLocation": GeoPoint(latitude: userLoc.latitude, longitude: userLoc.longitude),
            "dropoffLocation": GeoPoint(latitude: destLoc.latitude, longitude: destLoc.longitude),
            "status": "requested",
            "fareAmount": fareAmount,
            "estimatedTime": estimatedTime,
            "distance": distance,
            "timestamp": FieldValue.serverTimestamp()
        ]

        rideService.addRide(data: rideData) { result in
            switch result {
            case .success(let rideId):
                statusMessage = "Ride scheduled successfully!"
                print("Ride Scheduled: \(rideId)")
                self.listenForRideUpdates(rideId: rideId)
                self.notifyDriversOfNewRide(rideId: rideId)
            case .failure(let error):
                statusMessage = "Error scheduling ride: \(error.localizedDescription)"
            }
        }
    }
    private func notifyDriversOfNewRide(rideId: String) {
        let db = Firestore.firestore()
        db.collection("availableRides").document(rideId).setData([
            "rideId": rideId,
            "status": "requested",
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error notifying drivers: \(error.localizedDescription)")
            } else {
                print("Drivers notified of new ride.")
            }
        }
    }

    private func calculateEstimatedFare(distance: Double) -> Double {
        let baseFare = 5.0
        let perKmRate = 2.0
        return baseFare + (perKmRate * distance)
    }

    private func calculateEstimatedTime(distance: Double) -> String {
        let speed = 40.0 // Average speed in km/h
        let timeInHours = distance / speed
        let timeInMinutes = timeInHours * 60
        return "\(Int(timeInMinutes)) mins"
    }
    // cancel,fetch,and

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }

    private func listenForRideUpdates(rideId: String) {
        let rideDocument = Firestore.firestore().collection("rides").document(rideId)
        rideDocument.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for ride updates: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("Ride data not found.")
                return
            }

            if let status = data["status"] as? String {
                DispatchQueue.main.async {
                    statusMessage = "Ride status: \(status)"
                }
            }

            if let driverId = data["driverId"] as? String {
                DispatchQueue.main.async {
                    statusMessage = "Driver accepted the ride. Driver ID: \(driverId)"
                }
            }
        }
    }
    

}
extension Double {
    var degreesToRadians: Double {
        return self * .pi / 180.0
    }
}
/*struct RideSchedulingView: View {
    @State private var annotations: [AnnotatedLocation] = []
    @State private var driverLocation: CLLocationCoordinate2D? = nil
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var destinationLocation: CLLocationCoordinate2D? = nil
    @State private var routePolyline: MKPolyline? = nil
    @State private var userRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var rideId: String = ""
    @State private var statusMessage: String = ""
    @State private var isScheduling: Bool = false
    @State private var isRideFetched: Bool = false
    @StateObject private var locationManager = LocationManager()
    private let rideService = FirestoreRideService()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pickup Location Input
                    HStack {
                        TextField("Pickup Location", text: $pickupLocation)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        Button(action: fetchUserLocation) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    // Drop-off Location Input
                    TextField("Drop-off Location", text: $dropoffLocation)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: scheduleRide) {
                            
                            Text("Schedule Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                      // .disabled(isScheduling)

                        Button(action: fetchRide) {
                            Text("Fetch Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        if isRideFetched {
                            Button(action: cancelRide) {
                                Text("Cancel Ride")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Map View with Annotations and Route Overlay
                    Map(coordinateRegion: $userRegion, annotationItems: getAnnotations()) { location in
                        MapAnnotation(coordinate: location.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(location.label == "Driver Location" ? .green : .blue)
                                    .font(.title)
                                Text(location.label)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()

                    // Status Message
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .navigationTitle("Ride Scheduling")
                .onAppear {
                    setupLocationManager()
                    listenForDriverUpdates()
                }
            }
        }
    }
    

    struct AnnotatedLocation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let label: String
    }

    // MARK: - Functions

    private func setupLocationManager() {
        locationManager.requestAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func fetchUserLocation() {
        guard let location = locationManager.currentLocation else {
            statusMessage = "Unable to fetch user location."
            return
        }
        userLocation = location.coordinate
        userRegion.center = location.coordinate

        fetchAddress(from: location.coordinate) { address in
            pickupLocation = address ?? "Failed to fetch address"
        }
    }

    private func listenForDriverUpdates() {
        rideService.listenForDriverLocation { location in
            self.driverLocation = location
            updateRoute()
        }
    }

    private func fetchAddress(from location: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let locationObj = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(locationObj) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.postalCode]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                completion(address)
            } else {
                completion(nil)
            }
        }
    }

    private func getAnnotations() -> [AnnotatedLocation] {
        var annotations: [AnnotatedLocation] = []

        if let userLocation = userLocation {
            annotations.append(AnnotatedLocation(coordinate: userLocation, label: "Pickup Location"))
        }
        if let destination = destinationLocation {
            annotations.append(AnnotatedLocation(coordinate: destination, label: "Drop-off Location"))
        }
        if let driver = driverLocation {
            annotations.append(AnnotatedLocation(coordinate: driver, label: "Driver Location"))
        }

        return annotations
    }
    // fetch ride and cancel ride funcs
    
    private func fetchRide() {
        guard !rideId.isEmpty else {
            statusMessage = "Please enter a ride ID to fetch."
            return
        }

        rideService.fetchRide(rideId: rideId) { result in
            switch result {
            case .success(let data):
                statusMessage = "Ride data: \(data)"
                isRideFetched = true
            case .failure(let error):
                statusMessage = "Error fetching ride: \(error.localizedDescription)"
                isRideFetched = false
            }
        }
    }

    private func cancelRide() {
        guard !rideId.isEmpty else {
            statusMessage = "Please enter a ride ID to cancel."
            return
        }

        rideService.updateRideStatus(rideId: rideId, newStatus: "cancelled") { result in
            switch result {
            case .success:
                statusMessage = "Ride cancelled successfully."
                isRideFetched = false
            case .failure(let error):
                statusMessage = "Error cancelling ride: \(error.localizedDescription)"
            }
        }
    }
    // update route func
    // MARK: - Route Drawing
    private func updateRoute() {
        guard let driverLocation = driverLocation else { return }

        let source = MKMapItem(placemark: MKPlacemark(coordinate: driverLocation))
        let destinationCoordinate = userLocation ?? destinationLocation
        guard let destinationCoordinate = destinationCoordinate else { return }

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                statusMessage = "Error calculating route: \(error.localizedDescription)"
                return
            }

            if let route = response?.routes.first {
                self.routePolyline = route.polyline
                self.userRegion = MKCoordinateRegion(route.polyline.boundingMapRect)
            }
        }
    }
    // schedule ride func
    private func scheduleRide() {
        print("Schedule Ride Button Tapped")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            self.statusMessage = "User not logged in."
            print("Error: User not logged in.")
            return
        }

        guard let userLoc = userLocation, let destLoc = destinationLocation else {
            self.statusMessage = "Pickup and dropoff locations are required."
            print("Error: Pickup and dropoff locations are missing.")
            return
        }

        print("Scheduling Ride with:")
        print("User Location: \(userLoc)")
        print("Destination Location: \(destLoc)")

        let distance = calculateDistance(from: userLoc, to: destLoc)
        let fareAmount = calculateEstimatedFare(distance: distance)
        let estimatedTime = calculateEstimatedTime(distance: distance)

        print("Calculated Distance: \(distance)")
        print("Estimated Fare: \(fareAmount)")
        print("Estimated Time: \(estimatedTime)")

        // Save to Firestore
        let rideData: [String: Any] = [
            "passengerId": userId,
            "passengerName": Auth.auth().currentUser?.displayName ?? "Anonymous",
            "pickupLocation": GeoPoint(latitude: userLoc.latitude, longitude: userLoc.longitude),
            "dropoffLocation": GeoPoint(latitude: destLoc.latitude, longitude: destLoc.longitude),
            "status": "requested",
            "fareAmount": fareAmount,
            "estimatedTime": estimatedTime,
            "distance": distance,
            "timestamp": FieldValue.serverTimestamp()
        ]

        rideService.addRide(data: rideData) { result in
            switch result {
            case .success(let rideId):
                self.statusMessage = "Ride scheduled successfully!"
                print("Ride Scheduled: \(rideId)")
                self.listenForRideUpdates(rideId: rideId)
            case .failure(let error):
                self.statusMessage = "Error scheduling ride: \(error.localizedDescription)"
                print("Error Scheduling Ride: \(error.localizedDescription)")
            }
        }
    }

    private func calculateEstimatedFare(distance: Double) -> Double {
        let baseFare = 5.0
        let perKmRate = 2.0
        return baseFare + (perKmRate * distance)
    }
    private func calculateEstimatedTime(distance: Double) -> String {
        let speed = 40.0 // Average speed in km/h
        let timeInHours = distance / speed
        let timeInMinutes = timeInHours * 60
        return "\(Int(timeInMinutes)) mins"
    }
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
    // listen for ride updates func
    private func listenForRideUpdates(rideId: String) {
        let rideDocument = Firestore.firestore().collection("rides").document(rideId)
        rideDocument.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for ride updates: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("Ride data not found.")
                return
            }

            if let status = data["status"] as? String {
                DispatchQueue.main.async {
                    self.statusMessage = "Ride status: \(status)"
                }
            }

            if let driverId = data["driverId"] as? String {
                DispatchQueue.main.async {
                    self.statusMessage = "Driver accepted the ride. Driver ID: \(driverId)"
                }
            }
        }
    }

}*/
//extension Double {
//    var degreesToRadians: Double {
//        return self * .pi / 180.0
 //   }
//}



/*import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct RideSchedulingView: View {
    @State private var driverLocation: CLLocationCoordinate2D? = nil
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var destinationLocation: CLLocationCoordinate2D? = nil
    @State private var routePolyline: MKPolyline? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var rideId: String = ""
    @State private var statusMessage: String = ""
    @State private var isScheduling: Bool = false
    @State private var isRideFetched: Bool = false
    @StateObject private var locationManager = LocationManager()
    private let rideService = FirestoreRideService()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pickup Location Input
                    HStack {
                        TextField("Pickup Location", text: $pickupLocation)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        Button(action: fetchUserLocation) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    // Drop-off Location Input
                    TextField("Drop-off Location", text: $dropoffLocation)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: scheduleRide) {
                            Text(isScheduling ? "Scheduling..." : "Schedule Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isScheduling)

                        Button(action: fetchRide) {
                            Text("Fetch Ride")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        if isRideFetched {
                            Button(action: cancelRide) {
                                Text("Cancel Ride")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Map View with Annotations and Route Overlay
                    Map(coordinateRegion: $region, annotationItems: getAnnotations()) { location in
                        MapAnnotation(coordinate: location.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(location.label == "Driver Location" ? .green : .blue)
                                    .font(.title)
                                Text(location.label)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .overlay(
                        GeometryReader { _ in
                            if let route = routePolyline {
                                RoutePolylineOverlay(polyline: route)
                            }
                        }
                    )
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()

                    // Status Message
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .navigationTitle("Ride Scheduling")
                .onAppear {
                    setupLocationManager()
                }
            }
        }
        .onAppear {
            listenForDriverUpdates()
        }
    }

    // MARK: - Firebase Listener
    private func listenForDriverUpdates() {
        rideService.listenForDriverLocation { location in
            self.driverLocation = location
            updateRoute()
        }
    }

    // MARK: - Route Drawing
    private func updateRoute() {
        guard let driverLocation = driverLocation else { return }

        let source = MKMapItem(placemark: MKPlacemark(coordinate: driverLocation))
        let destinationCoordinate = userLocation ?? destinationLocation
        guard let destinationCoordinate = destinationCoordinate else { return }

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                statusMessage = "Error calculating route: \(error.localizedDescription)"
                return
            }

            if let route = response?.routes.first {
                self.routePolyline = route.polyline
                self.region = MKCoordinateRegion(route.polyline.boundingMapRect)
            }
        }
    }

    // MARK: - Functions
    private func setupLocationManager() {
        locationManager.requestAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func fetchUserLocation() {
        guard let location = locationManager.currentLocation else {
            statusMessage = "Unable to fetch user location."
            return
        }
        userLocation = location
        region.center = location

        fetchAddress(from: location) { address in
            pickupLocation = address ?? "Failed to fetch address"
        }
    }

    private func scheduleRide() {
        guard !pickupLocation.isEmpty, !dropoffLocation.isEmpty else {
            statusMessage = "Please fill in both pickup and dropoff locations."
            return
        }

        isScheduling = true
        statusMessage = ""

        let pickupGeoPoint = GeoPoint(latitude: userLocation?.latitude ?? 0, longitude: userLocation?.longitude ?? 0)
        let dropoffGeoPoint = GeoPoint(latitude: destinationLocation?.latitude ?? 0, longitude: destinationLocation?.longitude ?? 0)

        rideService.addRide(
            passengerId: Auth.auth().currentUser?.uid ?? "unknown",
            passengerName: Auth.auth().currentUser?.displayName ?? "Anonymous",
            pickupLocation: pickupGeoPoint,
            dropoffLocation: dropoffGeoPoint,
            status: "requested"
        ) { result in
            isScheduling = false
            switch result {
            case .success:
                statusMessage = "Ride scheduled successfully!"
            case .failure(let error):
                statusMessage = "Error scheduling ride: \(error.localizedDescription)"
            }
        }
    }

    private func fetchRide() {
        guard !rideId.isEmpty else {
            statusMessage = "Please enter a ride ID to fetch."
            return
        }

        rideService.fetchRide(rideId: rideId) { result in
            switch result {
            case .success(let data):
                statusMessage = "Ride data: \(data)"
                isRideFetched = true
            case .failure(let error):
                statusMessage = "Error fetching ride: \(error.localizedDescription)"
                isRideFetched = false
            }
        }
    }

    private func cancelRide() {
        guard !rideId.isEmpty else {
            statusMessage = "Please enter a ride ID to cancel."
            return
        }

        rideService.updateRideStatus(rideId: rideId, newStatus: "cancelled") { result in
            switch result {
            case .success:
                statusMessage = "Ride cancelled successfully."
                isRideFetched = false
            case .failure(let error):
                statusMessage = "Error cancelling ride: \(error.localizedDescription)"
            }
        }
    }

    private func fetchAddress(from location: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let locationObj = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(locationObj) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.postalCode]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                completion(address)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Helpers
    private func getAnnotations() -> [AnnotatedLocation] {
        var annotations: [AnnotatedLocation] = []

        if let userLocation = userLocation {
            annotations.append(AnnotatedLocation(coordinate: userLocation, label: "Pickup Location"))
        }
        if let destination = destinationLocation {
            annotations.append(AnnotatedLocation(coordinate: destination, label: "Drop-off Location"))
        }
        if let driver = driverLocation {
            annotations.append(AnnotatedLocation(coordinate: driver, label: "Driver Location"))
        }

        return annotations
    }
}*/

// MARK: - Annotated Location Model

/*
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
}*/
 
// calculate Estimated time
/*   private func calculateEstimatedTime(distance: Double) -> String {
    let averageSpeed = 50.0 // Average speed in km/h
    let distance = calculateDistance() // Distance in kilometers

    guard distance > 0 else {
        return "N/A"
    }

    let timeInHours = distance / averageSpeed
    let timeInMinutes = timeInHours * 60

    return "\(Int(timeInMinutes)) mins" // Estimated time in minutes
}
 // calculate distance
private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers


    let earthRadius = 6371.0 // Earth's radius in kilometers

    let dLat = (destinationLocation.latitude - userLocation.latitude).degreesToRadians
    let dLon = (destinationLocation.longitude - userLocation.longitude).degreesToRadians

    let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(userLocation.latitude.degreesToRadians) *
            cos(destinationLocation.latitude.degreesToRadians) *
            sin(dLon / 2) * sin(dLon / 2)

    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    let distance = earthRadius * c

    return distance // Distance in kilometers
}
// calculaate Estimated fare
private func calculateEstimatedFare(distance: Double) -> Double {
    let baseFare = 5.0 // Base fare in dollars
    let ratePerKilometer = 2.0 // Rate per kilometer in dollars
    let distance = calculateDistance() // Distance in kilometers

    guard distance > 0 else {
        return baseFare // If distance is 0, return base fare
    }

    let fare = baseFare + (ratePerKilometer * distance)
    return round(fare * 100) / 100 // Round to 2 decimal places
}*/
