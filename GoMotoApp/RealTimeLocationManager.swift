//
//  RealTimeLocationManager.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//


import CoreLocation
import Combine

class RealTimeLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RealTimeLocationManager()
    
    @Published var driverLocation: CLLocation?
    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        driverLocation = locations.last
    }
}