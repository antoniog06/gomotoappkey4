import SwiftUI
import MapKit

struct LiveMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack {
            Text("Live Ride Tracking")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Map(coordinateRegion: $region)
                .frame(height: 300)
                .cornerRadius(15)
                .padding()

            Text("Ride is on the way!")
                .foregroundColor(.blue)
                .font(.headline)

            Spacer()
        }
        .padding()
    }
}

struct LiveMapView_Previews: PreviewProvider {
    static var previews: some View {
        LiveMapView()
    }
}