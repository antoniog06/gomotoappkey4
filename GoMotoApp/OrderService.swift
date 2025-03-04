//
//  OrderService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import SwiftUI
import FirebaseFirestore

class OrderService {
    private let db = Firestore.firestore()
    
    // 🚀 Place Order: Handles Ride & Food Orders Dynamically
    func placeOrder(userID: String, storeID: String?, items: [String]?, totalAmount: Double, isRide: Bool) {
        if isRide {
            assignDriverForRide(userID: userID, totalAmount: totalAmount)
        } else if let storeID = storeID, let items = items {
            handleFoodOrder(userID: userID, storeID: storeID, items: items, totalAmount: totalAmount)
        }
    }
    
    // ✅ Assign Driver for Ride
    private func assignDriverForRide(userID: String, totalAmount: Double) {
        db.collection("drivers")
            .whereField("status", isEqualTo: "available")
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in // ✅ Capture self explicitly
                guard let self = self else { return } // ✅ Ensure self is still available
                
                if let error = error {
                    print("Error finding driver: \(error.localizedDescription)")
                    return
                }

                if let driver = snapshot?.documents.first {
                    let driverID = driver.documentID
                    
                    self.db.collection("ride_orders").addDocument(data: [ // ✅ Use self.db
                        "driverID": driverID,
                        "userID": userID,
                        "totalAmount": totalAmount,
                        "status": "assigned"
                    ]) { error in
                        if let error = error {
                            print("Error assigning driver: \(error.localizedDescription)")
                        } else {
                            print("✅ Driver \(driverID) assigned for ride order.")
                        }
                    }
                }
            }
    }

    // ✅ Handle Food Order
    private func handleFoodOrder(userID: String, storeID: String, items: [String], totalAmount: Double) {
        let storeRef = db.collection("stores").document(storeID)
        
        storeRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let storeSupportsOnlineOrders = document.data()?["supportsOnlineOrders"] as? Bool ?? false
                
                if storeSupportsOnlineOrders {
                    self.sendOrderToStore(storeID: storeID, userID: userID, items: items, totalAmount: totalAmount)
                } else {
                    self.assignDriverToShop(userID: userID, storeID: storeID, items: items, totalAmount: totalAmount)
                }
            }
        }
    }
    
    // ✅ Send Order Directly to Store
    private func sendOrderToStore(storeID: String, userID: String, items: [String], totalAmount: Double) {
        db.collection("store_orders").addDocument(data: [
            "storeID": storeID,
            "userID": userID,
            "items": items,
            "totalAmount": totalAmount,
            "status": "pending"
        ]) { error in
            if let error = error {
                print("Error sending order to store: \(error.localizedDescription)")
            } else {
                print("Order sent to store \(storeID).")
            }
        }
    }
    
    // 🚀 Assign Closest Driver to Shop & Deliver
    private func assignDriverToShop(userID: String, storeID: String, items: [String], totalAmount: Double) {
        db.collection("drivers")
            .whereField("status", isEqualTo: "available")
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in // ✅ Capture self explicitly
                guard let self = self else { return } // ✅ Ensure self is still available
                
                if let error = error {
                    print("Error finding driver: \(error.localizedDescription)")
                    return
                }

                if let driver = snapshot?.documents.first {
                    let driverID = driver.documentID
                    
                    self.db.collection("driver_orders").addDocument(data: [ // ✅ Use self.db
                        "driverID": driverID,
                        "userID": userID,
                        "storeID": storeID,
                        "items": items,
                        "totalAmount": totalAmount,
                        "status": "assigned"
                    ]) { error in
                        if let error = error {
                            print("Error assigning driver: \(error.localizedDescription)")
                        } else {
                            print("✅ Driver \(driverID) assigned to shop for order.")
                        }
                    }
                }
            }
    }
    // 🚀 Place Order & Send SMS to Store
    func placeFoodOrder(userID: String, storeID: String, items: [String], totalAmount: Double) {
        let orderData: [String: Any] = [
            "storeID": storeID,
            "userID": userID,
            "items": items,
            "totalAmount": totalAmount,
            "status": "pending"
        ]
        
        db.collection("orders").addDocument(data: orderData) { error in
            if let error = error {
                print("Error saving order: \(error.localizedDescription)")
            } else {
                print("Order saved successfully! Sending SMS alert...")
                self.sendSMSNotification(storeID: storeID, orderDetails: orderData)
            }
        }
    }
    
    // ✅ Send SMS to Store (Twilio API or Similar Service)
    private func sendSMSNotification(storeID: String, orderDetails: [String: Any]) {
        let smsText = "New Order! Total: $\(orderDetails["totalAmount"] ?? 0.0). Confirm: https://yourapp.com/store/confirm?id=\(storeID)"
        
        // Send SMS via API (Twilio, Vonage, etc.)
        let apiURL = URL(string: "https://smsapi.com/send?to=\(storeID)&message=\(smsText)")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send SMS: \(error.localizedDescription)")
            } else {
                print("SMS sent successfully!")
            }
        }.resume()
    }
}


// to creates a web query for the store to aaccept order  manuaally

 /*   db.collection("orders").where("storeID", "==", currentStoreID)
       .onSnapshot(snapshot => {
           snapshot.forEach(order => {
               console.log("New Order:", order.data());
           });
       });
// Web Dashboard (React.Js)
import React, { useEffect, useState } from "react";
import { db } from "./firebase"; // Firebase Firestore config
import "./Dashboard.css";

const StoreDashboard = () => {
    const [orders, setOrders] = useState([]);

    useEffect(() => {
        const unsubscribe = db.collection("orders")
            .where("storeID", "==", "store_001") // Replace with actual store ID
            .onSnapshot(snapshot => {
                setOrders(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
            });

        return () => unsubscribe();
    }, []);

    const handleAcceptOrder = (orderID) => {
        db.collection("orders").doc(orderID).update({
            status: "accepted"
        });
        alert("Order Accepted!");
    };

    const handleRejectOrder = (orderID) => {
        db.collection("orders").doc(orderID).update({
            status: "rejected"
        });
        alert("Order Rejected!");
    };

    return (
        <div className="dashboard">
            <h2>Store Orders</h2>
            {orders.map(order => (
                <div key={order.id} className="order-card">
                    <h4>Order #{order.id}</h4>
                    <p><strong>Items:</strong> {order.items.join(", ")}</p>
                    <p><strong>Total:</strong> ${order.totalAmount.toFixed(2)}</p>
                    <p><strong>Status:</strong> {order.status}</p>
                    {order.status === "pending" && (
                        <div>
                            <button onClick={() => handleAcceptOrder(order.id)} className="accept-btn">Accept</button>
                            <button onClick={() => handleRejectOrder(order.id)} className="reject-btn">Reject</button>
                        </div>
                    )}
                </div>
            ))}
        </div>
    );
};

export default StoreDashboard;*/
/*private func assignDriverToShop(userID: String, storeID: String, items: [String], totalAmount: Double) {
 db.collection("drivers").whereField("status", isEqualTo: "available").limit(to: 1).getDocuments { (snapshot, error) in
     if let error = error {
         print("Error finding driver: \(error.localizedDescription)")
         return
     }
     
     if let driver = snapshot?.documents.first {
         let driverID = driver.documentID
         
         db.collection("driver_orders").addDocument(data: [
             "driverID": driverID,
             "userID": userID,
             "storeID": storeID,
             "items": items,
             "totalAmount": totalAmount,
             "status": "assigned"
         ]) { error in
             if let error = error {
                 print("Error assigning driver: \(error.localizedDescription)")
             } else {
                 print("Driver \(driverID) assigned to shop for order.")
             }
         }
     }
 }
}*/
/*  private func assignDriverForRide(userID: String, totalAmount: Double) {
 db.collection("drivers").whereField("status", isEqualTo: "available").limit(to: 1).getDocuments { (snapshot, error) in
     if let error = error {
         print("Error finding driver: \(error.localizedDescription)")
         return
     }
     if let driver = snapshot?.documents.first {
         let driverID = driver.documentID
         
         
         db.collection("ride_orders").addDocument(data: [
             "driverID": driverID,
             "userID": userID,
             "totalAmount": totalAmount,
             "status": "assigned"
         ]) { error in
             if let error = error {
                 print("Error assigning driver: \(error.localizedDescription)")
             } else {
                 print("Driver \(driverID) assigned for ride order.")
             }
         }
     }
 }
}*/
