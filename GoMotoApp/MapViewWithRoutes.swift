//
//  MapViewWithRoutes.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/26/25.
//

import SwiftUI
import MapKit

struct MapViewWithRoutes: UIViewRepresentable {
    var driverLocation: CLLocationCoordinate2D?
    var pickupLocation: CLLocationCoordinate2D
    var dropoffLocation: CLLocationCoordinate2D
    @Binding var mapView: MKMapView

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        updateAnnotations()
        drawRoute()
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        updateAnnotations()
        drawRoute()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    private func updateAnnotations() {
        mapView.removeAnnotations(mapView.annotations)

        // Add driver location pin
        if let driverLoc = driverLocation {
            let driverAnnotation = MKPointAnnotation()
            driverAnnotation.coordinate = driverLoc
            driverAnnotation.title = "Driver"
            mapView.addAnnotation(driverAnnotation)
        }

        // Add pickup location pin
        let pickupAnnotation = MKPointAnnotation()
        pickupAnnotation.coordinate = pickupLocation
        pickupAnnotation.title = "Pickup Location"
        mapView.addAnnotation(pickupAnnotation)

        // Add dropoff location pin
        let dropoffAnnotation = MKPointAnnotation()
        dropoffAnnotation.coordinate = dropoffLocation
        dropoffAnnotation.title = "Dropoff Location"
        mapView.addAnnotation(dropoffAnnotation)
    }

    private func drawRoute() {
        mapView.removeOverlays(mapView.overlays)
        
        let pickupPlacemark = MKPlacemark(coordinate: pickupLocation)
        let dropoffPlacemark = MKPlacemark(coordinate: dropoffLocation)

        // Route 1: Driver -> Pickup
        if let driverLoc = driverLocation {
            let driverPlacemark = MKPlacemark(coordinate: driverLoc)
            let driverToPickupRequest = MKDirections.Request()
            driverToPickupRequest.source = MKMapItem(placemark: driverPlacemark)
            driverToPickupRequest.destination = MKMapItem(placemark: pickupPlacemark)
            driverToPickupRequest.transportType = .automobile

            let driverToPickupDirections = MKDirections(request: driverToPickupRequest)
            driverToPickupDirections.calculate { response, error in
                if let route = response?.routes.first {
                    self.mapView.addOverlay(route.polyline)
                }
            }
        }

        // Route 2: Pickup -> Dropoff
        let pickupToDropoffRequest = MKDirections.Request()
        pickupToDropoffRequest.source = MKMapItem(placemark: pickupPlacemark)
        pickupToDropoffRequest.destination = MKMapItem(placemark: dropoffPlacemark)
        pickupToDropoffRequest.transportType = .automobile

        let pickupToDropoffDirections = MKDirections(request: pickupToDropoffRequest)
        pickupToDropoffDirections.calculate { response, error in
            if let route = response?.routes.first {
                self.mapView.addOverlay(route.polyline)
            }
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRoutes

        init(_ parent: MapViewWithRoutes) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 5
            return renderer
        }
    }
}


/*
import SwiftUI
import MapKit

struct MapViewWithRoutes: UIViewRepresentable {
    var driverLocation: Binding<CLLocationCoordinate2D?>
    var pickupLocation: CLLocationCoordinate2D
    var dropoffLocation: CLLocationCoordinate2D
    @Binding var mapView: MKMapView

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        // Draw route from Driver -> Pickup
        if let driverLoc = driverLocation.wrappedValue {
            drawRoute(
                from: driverLoc,
                to: pickupLocation,
                mapView: mapView,
                color: .blue,
                coordinator: context.coordinator
            )
        }
        
        // Draw route from Pickup -> Dropoff
        drawRoute(
            from: pickupLocation,
            to: dropoffLocation,
            mapView: mapView,
            color: .green,
            coordinator: context.coordinator
        )
    }

    private func drawRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, mapView: MKMapView, color: UIColor, coordinator: Coordinator) {
        let sourcePlacemark = MKPlacemark(coordinate: start)
        let destinationPlacemark = MKPlacemark(coordinate: end)
        
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
            let polyline = route.polyline
            mapView.addOverlay(polyline)
            coordinator.setColor(for: polyline, color: color)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRoutes
        private var overlayColors: [MKPolyline: UIColor] = [:]
        
        init(_ parent: MapViewWithRoutes) {
            self.parent = parent
        }
        
        func setColor(for overlay: MKPolyline, color: UIColor) {
            overlayColors[overlay] = color
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer() }
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = overlayColors[polyline] ?? .blue
            renderer.lineWidth = 5.0
            return renderer
        }
    }
}*/
