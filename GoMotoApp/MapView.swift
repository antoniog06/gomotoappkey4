//
//  MapView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/11/25.
//
import SwiftUI
import GoogleMaps
import FirebaseFirestore

struct GoogleMapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var destination: CLLocationCoordinate2D?
    @Binding var driverLocation: CLLocationCoordinate2D?

    private let mapView = GMSMapView()
    
    func makeUIView(context: Context) -> GMSMapView {
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true
        mapView.settings.zoomGestures = true
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        
        // Add User Marker
        if let userLocation = userLocation {
            let userMarker = GMSMarker(position: userLocation)
            userMarker.title = "Your Location"
            userMarker.icon = GMSMarker.markerImage(with: .blue)
            userMarker.map = mapView
        }
        
        // Add Destination Marker
        if let destination = destination {
            let destinationMarker = GMSMarker(position: destination)
            destinationMarker.title = "Destination"
            destinationMarker.icon = GMSMarker.markerImage(with: .red)
            destinationMarker.map = mapView
        }
        
        // Add Driver Marker
        if let driverLocation = driverLocation {
            let driverMarker = GMSMarker(position: driverLocation)
            driverMarker.title = "Driver"
            driverMarker.icon = GMSMarker.markerImage(with: .green)
            driverMarker.map = mapView
            
            // Draw Route from Driver to User or Destination
            if let userLocation = userLocation {
                drawRoute(from: driverLocation, to: userLocation, on: mapView)
            } else if let destination = destination {
                drawRoute(from: driverLocation, to: destination, on: mapView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // ✅ MARK: - Route Drawing with Google Directions API
    private func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, on mapView: GMSMapView) {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=driving&key=YOUR_GOOGLE_MAPS_API_KEY"
        
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let routes = json["routes"] as? [[String: Any]],
                   let firstRoute = routes.first,
                   let overviewPolyline = firstRoute["overview_polyline"] as? [String: Any],
                   let points = overviewPolyline["points"] as? String {
                    
                    DispatchQueue.main.async {
                        let path = GMSPath(fromEncodedPath: points)
                        let polyline = GMSPolyline(path: path)
                        polyline.strokeWidth = 5.0
                        polyline.strokeColor = .blue
                        polyline.map = mapView
                    }
                }
            } catch {
                print("❌ Error parsing route data: \(error.localizedDescription)")
            }
        }.resume()
    }

    // ✅ MARK: - Firestore Driver Location Updates
    func listenForDriverLocationUpdates(driverId: String) {
        let db = Firestore.firestore()
        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            if let lat = data["latitude"] as? CLLocationDegrees,
               let lon = data["longitude"] as? CLLocationDegrees {
                DispatchQueue.main.async {
                    self.driverLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            }
        }
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
    }
}
// old view bellow
/*import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var destination: CLLocationCoordinate2D?
    @Binding var driverLocation: CLLocationCoordinate2D?
    @Binding var mapView: MKMapView
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // User's location annotation
        if let userLocation = userLocation {
            let userAnnotation = MKPointAnnotation()
            userAnnotation.coordinate = userLocation
            userAnnotation.title = "Your Location"
            mapView.addAnnotation(userAnnotation)
        }

        // Destination annotation
        if let destination = destination {
            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.coordinate = destination
            destinationAnnotation.title = "Destination"
            mapView.addAnnotation(destinationAnnotation)
        }

        // Driver's location annotation
        if let driverLocation = driverLocation {
            let driverAnnotation = MKPointAnnotation()
            driverAnnotation.coordinate = driverLocation
            driverAnnotation.title = "Driver Location"
            mapView.addAnnotation(driverAnnotation)

            // Draw route if user location and destination are available
            if let userLocation = userLocation {
                drawRoute(from: driverLocation, to: userLocation, mapView: mapView)
            } else if let destination = destination {
                drawRoute(from: driverLocation, to: destination, mapView: mapView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // MARK: - Draw Route
    private func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, mapView: MKMapView) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                print("Error calculating route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // MARK: - Overlay Renderer
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(overlay: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    // MARK: - Driver Location Updates
    func listenForDriverLocationUpdates(driverId: String) {
        let db = Firestore.firestore()
        db.collection("drivers").document(driverId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            if let lat = data["latitude"] as? CLLocationDegrees,
               let lon = data["longitude"] as? CLLocationDegrees {
                DispatchQueue.main.async {
                    self.driverLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            }
        }
    }
}
*/
/*
import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var destination: CLLocationCoordinate2D?
    @Binding var driverLocation: CLLocationCoordinate2D?
    @Binding var mapView: MKMapView
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add annotations for user's location
        if let userLocation = userLocation {
            let userAnnotation = MKPointAnnotation()
            userAnnotation.coordinate = userLocation
            userAnnotation.title = "User Location"
            mapView.addAnnotation(userAnnotation)
        }

        // Add annotation for the destination
        if let destination = destination {
            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.coordinate = destination
            destinationAnnotation.title = "Destination"
            mapView.addAnnotation(destinationAnnotation)
        }

        // Add annotation for the driver's location
        if let driverLocation = driverLocation {
            let driverAnnotation = MKPointAnnotation()
            driverAnnotation.coordinate = driverLocation
            driverAnnotation.title = "Driver Location"
            mapView.addAnnotation(driverAnnotation)

            // Draw a route from the driver to the destination
            if let userLocation = userLocation {
                drawRoute(from: driverLocation, to: userLocation, mapView: mapView)
            } else if let destination = destination {
                drawRoute(from: driverLocation, to: destination, mapView: mapView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Draw Route
    private func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, mapView: MKMapView) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                print("Error calculating route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // MARK: - Overlay Renderer
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(overlay: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

*/
