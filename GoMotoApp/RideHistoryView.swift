//
//  RideHistoryView.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
//
import FirebaseAuth
import FirebaseAuth
import SwiftUI
import Firebase
import FirebaseFirestore

struct RideHistoryView: View {
    @State private var rideHistory: [RideRequest] = []
    @State private var selectedRide: RideRequest?
    @State private var showRideDetail = false
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Ride History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if rideHistory.isEmpty {
                    VStack {
                        Image(systemName: "car.fill")
                            .resizable()
                            .frame(width: 80, height: 50)
                            .foregroundColor(.gray)
                            .opacity(0.6)
                        
                        Text("No rides found.")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                    .padding(.top, 50)
                } else {
                    List(rideHistory) { ride in
                        RideHistoryCard(ride: ride) {
                            selectedRide = ride
                            showRideDetail.toggle()
                        }
                        .transition(.slide)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .padding(.horizontal)
            .onAppear { fetchRideHistory() }
            .sheet(isPresented: $showRideDetail) {
                if let ride = selectedRide {
                    RideDetailView(ride: ride)
                }
            }
        }
    }
}

// MARK: - 🔹 RideHistoryCard View
struct RideHistoryCard: View {
    var ride: RideRequest
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Pickup: \(ride.pickupAddress ?? "Unknown")")
                        .font(.headline)
                    Text("Dropoff: \(ride.dropoffAddress ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Fare: $\(ride.fareAmount ?? 0.0, specifier: "%.2f")")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(ride.status)
                    .fontWeight(.bold)
                    .foregroundColor(ride.status == "Completed" ? .green : .red)
            }
            .padding()
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))
        .onTapGesture { onTap() }
        .padding(.vertical, 5)
    }
}

// MARK: - 🔹 RideDetailView (For Detailed Ride Receipt)
struct RideDetailView: View {
    var ride: RideRequest
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Ride Summary")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Pickup Address: \(ride.pickupAddress ?? "N/A")")
                Text("Dropoff Address: \(ride.dropoffAddress ?? "N/A")")
                Text("Distance: \(ride.distance ?? 0.0, specifier: "%.2f") km")
                Text("Fare: $\(ride.fareAmount ?? 0.0, specifier: "%.2f")")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                Text("Payment Method: \(ride.paymentMethod ?? "N/A")")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(radius: 5))
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 🔹 Fetch Ride History from Firestore
extension RideHistoryView {
    private func fetchRideHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRole = "driver" // Or fetch this from Firestore if you store user roles
        
        let queryField = userRole == "driver" ? "driverId" : "userId"
        
        db.collection("rides")
            .whereField(queryField, isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, _ in
                self.rideHistory = snapshot?.documents.map { RideRequest(doc: $0) } ?? []
            }
    }
}

// MARK: - 🔹 RideRequest Model


/*import SwiftUI

struct RideHistoryView: View {
    @State private var rides = [
        ("12/19/2024", "Completed", "$10.00"),
        ("12/18/2024", "Cancelled", "$0.00"),
        ("12/17/2024", "Completed", "$20.00")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Ride History")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            List(rides, id: \.0) { ride in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Date: \(ride.0)")
                        Text("Status: \(ride.1)")
                            .foregroundColor(ride.1 == "Completed" ? .green : .red)
                    }
                    Spacer()
                    Text("\(ride.2)")
                        .font(.headline)
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()
        }
        .padding()
    }
}

struct RideHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        RideHistoryView()
    }
}
*/
