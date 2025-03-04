
import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // Singleton instance

    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()

    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationError: Error?
    @Published var userLocation: CLLocationCoordinate2D?

    private override init() {
        super.init()
        locationManager.delegate = self // ✅ Set delegate here
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // ✅ Optimize updates
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        requestAuthorization()
    }

    func requestAuthorization() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            handleAuthorizationStatus(status)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            } else {
                self.locationError = NSError(domain: "LocationAuthorization", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Location authorization denied."
                ])
            }
        }
    }

 

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.userLocation = location.coordinate
            self.driverLocation = location.coordinate
            self.updateDriverLocationInFirestore(location: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
        }
    }

    private func updateDriverLocationInFirestore(location: CLLocation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        db.collection("drivers").document(userId).updateData(["location": geoPoint]) { error in
            if let error = error {
                print("Error updating driver location: \(error.localizedDescription)")
            }
        }
        
    
        
        
        // MARK: - Location Manager Delegate
        
            
            // Handle authorization status changes
            func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                handleAuthorizationStatus(manager.authorizationStatus)
            }
            
            // Unified authorization handling function
             func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
                DispatchQueue.main.async {
                    self.authorizationStatus = status  // Assuming you have a property to store this
                    
                    switch status {
                    case .authorizedWhenInUse, .authorizedAlways:
                        self.startUpdatingLocation()
                        print("✅ Location access granted.")
                        
                    case .denied, .restricted:
                        self.locationError = NSError(
                            domain: "LocationAuthorization",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Location access denied or restricted."]
                        )
                        print("🚫 Location access denied or restricted.")
                        
                    case .notDetermined:
                        print("⚠️ Location permission not determined yet.")
                        
                    @unknown default:
                        self.locationError = NSError(
                            domain: "UnknownAuthorizationStatus",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status."]
                        )
                        print("❓ Unknown authorization status.")
                    }
                }
            }
            
            // Handle actual location updates
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                guard let latestLocation = locations.last else { return }
                currentLocation = latestLocation  // Assuming you have a `currentLocation` property
                
                // Log or process the location update
                print("📍 Location updated: \(latestLocation.coordinate.latitude), \(latestLocation.coordinate.longitude)")
            }
        }
        
        
    
    
  /*  func startUpdatingLocation(completion: ((Result<CLLocation, Error>) -> Void)? = nil) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            if let currentLocation = self.currentLocation {
                completion?(.success(currentLocation))
            }
        } else {
            completion?(.failure(NSError(
                domain: "LocationServicesDisabled",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location services are disabled."]
            )))
        }
    }*/
    func startUpdatingLocation(completion: ((Result<CLLocation, Error>) -> Void)? = nil) {
        if CLLocationManager.locationServicesEnabled() {
            // Check authorization status first
            let authorizationStatus = locationManager.authorizationStatus
            
            switch authorizationStatus {
            case .notDetermined:
                // Request permission and wait for callback
                locationManager.requestWhenInUseAuthorization()
                
            case .authorizedWhenInUse, .authorizedAlways:
                // Run location updates on a background thread to avoid UI blocking
                DispatchQueue.global(qos: .background).async {
                    self.locationManager.startUpdatingLocation()
                    
                    if let currentLocation = self.currentLocation {
                        DispatchQueue.main.async {
                            completion?(.success(currentLocation))
                        }
                    }
                }
                
            case .restricted, .denied:
                completion?(.failure(NSError(
                    domain: "LocationPermissionDenied",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Location permissions are denied or restricted."]
                )))
                
            @unknown default:
                completion?(.failure(NSError(
                    domain: "UnknownAuthorizationStatus",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status."]
                )))
            }
            
        } else {
            completion?(.failure(NSError(
                domain: "LocationServicesDisabled",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location services are disabled."]
            )))
        }
    }
}



/*import Foundation
import CoreLocation
import Combine
import FirebaseFirestore

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    @Published var driverLocation: CLLocationCoordinate2D
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationError: Error?
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestAuthorization()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }

    // Request location authorization
    func requestAuthorization() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            handleAuthorizationStatus(status)
        }
    }

    // Handle location authorization changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        handleAuthorizationStatus(status)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Authorization granted. Starting location updates.")
                self.startUpdatingLocation()
            case .denied, .restricted:
                print("Authorization denied or restricted.")
                self.locationError = NSError(domain: "LocationAuthorization", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Location authorization denied or restricted."
                ])
            default:
                print("Authorization status not determined.")
            }
        }
    }

    // Start updating the location
    func startUpdatingLocation(completion: ((Result<CLLocation, Error>) -> Void)? = nil) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            // Call completion with the last known location if available
            if let currentLocation = self.currentLocation {
                completion?(.success(currentLocation))
            }
        } else {
            completion?(.failure(NSError(
                domain: "LocationServicesDisabled",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location services are disabled."]
            )))
        }
    }

    // Stop updating the location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // CLLocationManagerDelegate - Called when the location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.userLocation = location.coordinate
            print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }

    // CLLocationManagerDelegate - Called when there is an error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
            print("Location Manager Error: \(error.localizedDescription)")
        }
    }
}

*/


/*import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    
    @Published var currentLocation: CLLocationCoordinate2D? = nil
    @Published var errorMessage: String? = nil
    @Published var isUpdatingLocation: Bool = false
   
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
    }

    private func checkAuthorizationStatus() {
        // Check initial authorization status
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                requestAuthorization()
            case .restricted, .denied:
                DispatchQueue.main.async {
                    self.errorMessage = "Location access is restricted or denied."
                }
            case .authorizedWhenInUse, .authorizedAlways:
                startUpdatingLocation()
            @unknown default:
                DispatchQueue.main.async {
                    self.errorMessage = "Unknown authorization status encountered."
                }
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Location services are disabled."
            }
        }
    }

    func requestAuthorization() {
        DispatchQueue.main.async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.requestAlwaysAuthorization()
            } else {
                self.errorMessage = "Location services are disabled."
            }
        }
    }

    func startUpdatingLocation() {
        DispatchQueue.global().async {
            guard CLLocationManager.locationServicesEnabled() else {
                DispatchQueue.main.async {
                    self.errorMessage = "Location services are disabled."
                }
                return
            }

            guard self.locationManager.authorizationStatus == .authorizedAlways ||
                  self.locationManager.authorizationStatus == .authorizedWhenInUse else {
                DispatchQueue.main.async {
                    self.errorMessage = "Location access is not authorized."
                }
                return
            }

            self.locationManager.startUpdatingLocation()
            DispatchQueue.main.async {
                self.isUpdatingLocation = true
            }
        }
    }

    func stopUpdatingLocation() {
        DispatchQueue.global().async {
            self.locationManager.stopUpdatingLocation()
            DispatchQueue.main.async {
                self.isUpdatingLocation = false
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.global().async {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.startUpdatingLocation()
            case .restricted, .denied:
                DispatchQueue.main.async {
                    self.errorMessage = "Location access is restricted or denied."
                }
            case .notDetermined:
                break
            @unknown default:
                DispatchQueue.main.async {
                    self.errorMessage = "Unknown authorization status encountered."
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to update location: \(error.localizedDescription)"
        }
    }
    
    

    func fetchAddress(from location: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let error = error {
                print("Failed to get address: \(error.localizedDescription)")
                completion(nil)
            } else if let placemark = placemarks?.first {
                let address = [
                    placemark.subThoroughfare ?? "",
                    placemark.thoroughfare ?? "",
                    placemark.locality ?? "",
                    placemark.administrativeArea ?? "",
                    placemark.postalCode ?? ""
                ].filter { !$0.isEmpty }.joined(separator: ", ")
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
    // real time driver location updates
    func updateDriverLocationInFirestore(location: CLLocationCoordinate2D) {
        let db = Firestore.firestore()
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("drivers").document(driverId).setData([
            "latitude": location.latitude,
            "longitude": location.longitude
        ], merge: true)
    }

    
}*/
