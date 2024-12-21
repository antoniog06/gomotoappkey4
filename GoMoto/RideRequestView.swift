import SwiftUI

struct RideRequestView: View {
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var rideScheduled: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Request a Ride")
                .font(.title)
                .fontWeight(.bold)

            TextField("Pickup Location", text: $pickupLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Drop-off Location", text: $dropoffLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                scheduleRide()
            }) {
                Text("Schedule Ride")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(pickupLocation.isEmpty || dropoffLocation.isEmpty)

            if rideScheduled {
                Text("Ride Scheduled!")
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
    }

    private func scheduleRide() {
        // Simulate scheduling a ride
        rideScheduled = true
    }
}

struct RideRequestView_Previews: PreviewProvider {
    static var previews: some View {
        RideRequestView()
    }
}