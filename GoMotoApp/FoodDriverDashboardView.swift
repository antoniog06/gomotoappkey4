//
//  FoodDriverDashboardView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore



struct FoodDriverDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var availableOrders: [FoodOrder] = []
    @State private var activeOrder: FoodOrder?
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🍔 Food Delivery Dashboard")
                    .font(.largeTitle)
                    .bold()
                
                if let order = activeOrder {
                    activeOrderView(order: order)
                } else if availableOrders.isEmpty {
                    noAvailableOrdersView
                } else {
                    availableOrdersListView
                }
                
                Spacer()
                
                // Profile and Payment Links
                NavigationLink(destination: PaymentView()) {
                    Text("💳 Payments")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .onAppear {
                fetchAvailableOrders()
            }
            .navigationTitle("Food Delivery")
        }
    }
}

// 🚀 **Available Orders List**
extension FoodDriverDashboardView {
    private var noAvailableOrdersView: some View {
        Text("No available food deliveries.")
            .foregroundColor(.gray)
            .padding()
    }

    private var availableOrdersListView: some View {
        List(availableOrders) { order in
            VStack(alignment: .leading) {
                Text("📍 Pickup: \(order.restaurantName)")
                    .font(.headline)
                Text("🏠 Dropoff: \(order.customerAddress)")
                Text("💰 Pay: $\(String(format: "%.2f", order.fare))")
            }
            .onTapGesture {
                acceptOrder(order: order)
            }
        }
    }

    private func activeOrderView(order: FoodOrder) -> some View {
        VStack {
            Text("🚚 Delivering: \(order.restaurantName)")
                .font(.title2)
            Text("📦 Order Details: \(order.items.joined(separator: ", "))")
            Text("🏠 Dropoff: \(order.customerAddress)")
            
            Button("✅ Complete Delivery") {
                completeOrder(order: order)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// 🚀 **Fetch Orders**
extension FoodDriverDashboardView {
    private func fetchAvailableOrders() {
        db.collection("orders")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching orders: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.availableOrders = documents.map { FoodOrder(id: $0.documentID, data: $0.data()) }
            }
    }

    private func acceptOrder(order: FoodOrder) {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        let orderRef = db.collection("orders").document(order.id)

        orderRef.updateData([
            "status": "accepted",
            "driverId": driverId
        ]) { error in
            if let error = error {
                print("Error accepting order: \(error.localizedDescription)")
            } else {
                self.activeOrder = order
            }
        }
    }

    private func completeOrder(order: FoodOrder) {
        let orderRef = db.collection("orders").document(order.id)
        orderRef.updateData(["status": "delivered"]) { error in
            if let error = error {
                print("Error completing delivery: \(error.localizedDescription)")
            } else {
                self.activeOrder = nil
                fetchAvailableOrders()
            }
        }
    }
}

struct FoodOrder: Identifiable {
    var id: String
    var restaurantName: String
    var customerAddress: String
    var items: [String]
    var fare: Double

    init(id: String, data: [String: Any]) {
        self.id = id
        self.restaurantName = data["restaurantName"] as? String ?? "Unknown"
        self.customerAddress = data["customerAddress"] as? String ?? "Unknown"
        self.items = data["items"] as? [String] ?? []
        self.fare = data["fare"] as? Double ?? 0.0
    }
}
