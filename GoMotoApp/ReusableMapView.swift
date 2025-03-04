//
//  ReusableMapView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/26/25.
//


import SwiftUI
import MapKit

struct ReusableMapView: UIViewRepresentable {
    @Binding var driverLocation: CLLocationCoordinate2D?
    var pickupLocation: CLLocationCoordinate2D
    var dropoffLocation: CLLocationCoordinate2D
    var mapView: MKMapView = MKMapView()
    
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove old overlays and annotations
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add pins
        addPin(to: mapView, at: driverLocation, title: "Driver Location", color: .blue)
        addPin(to: mapView, at: pickupLocation, title: "Pickup Location", color: .green)
        addPin(to: mapView, at: dropoffLocation, title: "Dropoff Location", color: .red)
        
        // Draw routes
        if let driverLoc = driverLocation {
            drawRoute(from: driverLoc, to: pickupLocation, mapView: mapView, color: .blue, context: context)
        }
        drawRoute(from: pickupLocation, to: dropoffLocation, mapView: mapView, color: .green, context: context)
    }
    
    private func addPin(to mapView: MKMapView, at location: CLLocationCoordinate2D?, title: String, color: UIColor) {
        guard let location = location else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
    
  
    
    private func drawRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, mapView: MKMapView, color: UIColor, context: Context) {
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
            context.coordinator.setColor(for: polyline, color: color)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ReusableMapView
        private var overlayColors: [MKPolyline: UIColor] = [:]
        
        init(_ parent: ReusableMapView) {
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
}
