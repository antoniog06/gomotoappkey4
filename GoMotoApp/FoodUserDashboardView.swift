//
//  FoodUserDashboardView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//


import SwiftUI

import FirebaseFirestore
import FirebaseAuth


struct FoodUserDashboardView: View {
    @Binding var isLoggedIn: Bool
    @Binding var userOrders: [FoodOrder]
    private let db = Firestore.firestore()

    var body: some View {
        Text("🍽️ My Food Orders")
       /* NavigationView {
            VStack(spacing: 20) {
                Text("🍽️ My Food Orders")
                    .font(.largeTitle)
                    .bold()
                
                if userOrders.isEmpty {
                    Text("No food orders yet.")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(userOrders, id: \.id) { order in
                            VStack(alignment: .leading) {
                                Text("🍽 Restaurant: \(order.restaurantName)")
                                Text("💰 Total: $\(String(format: "%.2f", order.fare))")
                                Text("📦 Status: \(order.status)")
                            }
                        }
                    }
                }
            }
            .onAppear {
                //   fetchUserOrders()
            }
            .navigationTitle("Food Orders")
        }*/
    }
}
/*    private func fetchUserOrders() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("orders")
            .whereField("userID", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching orders: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.userOrders = documents.map { FoodOrder(id: $0.documentID, data: $0.data()) }
            }
    }
}*/
