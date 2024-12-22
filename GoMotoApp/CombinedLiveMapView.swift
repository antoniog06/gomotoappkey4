import SwiftUI
import MapKit

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}

struct CombinedLiveMapView: View {
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Example coordinates for San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText: String = ""
    @State private var searchResults: [IdentifiableMapItem] = []
    @State private var showUserLocation: Bool = true
    
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var rideScheduled: Bool = false
    
    var body: some View {
        VStack {
            // Search and Ride Request Section
            VStack(spacing: 20) {
                HStack {
                    TextField("Search location", text: $searchText, onCommit: performSearch)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                }
                TextField("Pickup Location", text: $pickupLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Drop-off Location", text: $dropoffLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: scheduleRide) {
                    Text("Schedule Ride")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(pickupLocation.isEmpty || dropoffLocation.isEmpty)
                
                if rideScheduled {
                    Text("Ride Scheduled!")
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .padding(.top)
            
            // Map Section
            Map(
                coordinateRegion: $coordinateRegion,
                showsUserLocation: showUserLocation,
                annotationItems: searchResults
            ) { result in
                MapMarker(coordinate: result.mapItem.placemark.coordinate, tint: .red)
            }
            .ignoresSafeArea(edges: .all)
        }
    }
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Error searching: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            searchResults = response.mapItems.map { IdentifiableMapItem(mapItem: $0) }
            if let firstResult = searchResults.first {
                coordinateRegion.center = firstResult.mapItem.placemark.coordinate
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = CLLocationManager().location?.coordinate {
            coordinateRegion.center = userLocation
        } else {
            print("User location not available.")
        }
    }
    
    private func scheduleRide() {
        // Simulate scheduling a ride
        rideScheduled = true
    }
}

struct CombinedLiveMapView_Previews: PreviewProvider {
    static var previews: some View {
        CombinedLiveMapView()
    }
}

