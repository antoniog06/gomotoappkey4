//
//  FoodDeliveryView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FoodDeliveryView: View {
    @State private var restaurantName: String = ""
    @State private var orderDetails: String = ""
    @State private var estimatedCost: Double = 0.0
    @State private var isPlacingOrder = false
    @State private var orderConfirmed = false
    @State private var orderID: String?

    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Order Food Delivery").font(.largeTitle).bold()

            // Restaurant Name Field
            TextField("Enter Restaurant Name", text: $restaurantName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Order Details
            TextField("Enter Order Details", text: $orderDetails)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Estimate Cost Button
            Button("Estimate Cost") {
                estimatedCost = calculateCost()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Estimated Cost Display
            if estimatedCost > 0 {
                Text("Estimated Cost: $\(estimatedCost, specifier: "%.2f")")
                    .font(.title2)
                    .padding()
            }

            // Place Order Button
            Button(isPlacingOrder ? "Placing Order..." : "Place Order") {
                placeOrder()
            }
            .disabled(isPlacingOrder || restaurantName.isEmpty || orderDetails.isEmpty)
            .padding()
            .background(isPlacingOrder ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Confirmation Message
            if orderConfirmed {
                Text("Order Confirmed! Order ID: \(orderID ?? "N/A")")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}

// MARK: - 🍔 Order Logic
extension FoodDeliveryView {
    private func calculateCost() -> Double {
        let basePrice = 5.0
        let foodCost = Double.random(in: 10...50) // Simulated price
        return basePrice + foodCost
    }

    private func placeOrder() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isPlacingOrder = true

        let orderData: [String: Any] = [
            "userID": userId,
            "restaurant": restaurantName,
            "orderDetails": orderDetails,
            "estimatedCost": estimatedCost,
            "status": "pending",
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("orders").addDocument(data: orderData) { error in
            isPlacingOrder = false
            if let error = error {
                print("⚠️ Order failed: \(error.localizedDescription)")
            } else {
                orderConfirmed = true
                orderID = orderData["orderID"] as? String
                print("✅ Order successfully placed!")
            }
        }
    }
}