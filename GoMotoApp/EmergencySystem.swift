//
//  EmergencySystem.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/3/25.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import CoreLocation

class EmergencySystem {
    static let shared = EmergencySystem() // Singleton instance
    private let db = Firestore.firestore()

    private init() {}
    
    class EmergencySystem {
        static let shared = EmergencySystem()

        func triggerEmergency(userLocation: String, rideDetails: String) {
            print("🚨 Emergency triggered! Location: \(userLocation), Ride: \(rideDetails)")
            // Add logic to notify authorities, send alerts, and call emergency contacts
        }
    }

    // 🚨 Trigger Emergency
    func triggerEmergency(for rideId: String, userLocation: CLLocationCoordinate2D?) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let timestamp = Timestamp(date: Date())
        let emergencyData: [String: Any] = [
            "rideId": rideId,
            "userId": userId,
            "latitude": userLocation?.latitude ?? 0.0,
            "longitude": userLocation?.longitude ?? 0.0,
            "timestamp": timestamp,
            "status": "Active"
        ]

        // ✅ Save to Firestore (for authorities)
        db.collection("emergencies").addDocument(data: emergencyData) { error in
            if let error = error {
                print("❌ Error saving emergency report: \(error.localizedDescription)")
            } else {
                print("✅ Emergency report logged successfully!")
            }
        }

        // ✅ Notify Authorities
        notifyAuthorities(rideId: rideId, location: userLocation)

        // ✅ Alert Nearby Drivers
        alertNearbyDrivers(rideId: rideId, location: userLocation)

        // ✅ Notify Emergency Contacts
        notifyEmergencyContacts(userId: userId, location: userLocation)

        // ✅ Trigger App UI Alert
        triggerUserAlert()
    }
}
extension EmergencySystem {
    private func notifyAuthorities(rideId: String, location: CLLocationCoordinate2D?) {
        let emergencyReport: [String: Any] = [
            "rideId": rideId,
            "latitude": location?.latitude ?? 0.0,
            "longitude": location?.longitude ?? 0.0,
            "status": "Pending Response",
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("emergencyReports").addDocument(data: emergencyReport) { error in
            if let error = error {
                print("❌ Error reporting to authorities: \(error.localizedDescription)")
            } else {
                print("🚔 Authorities notified successfully!")
            }
        }
    }
}
extension EmergencySystem {
    private func alertNearbyDrivers(rideId: String, location: CLLocationCoordinate2D?) {
        guard let location = location else { return }

        let driversRef = db.collection("drivers")
            .whereField("isAvailable", isEqualTo: true) // Find active drivers

        driversRef.getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("❌ Error fetching nearby drivers: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            for doc in documents {
                if let driverLocation = doc.data()["location"] as? GeoPoint {
                    let driverCoordinates = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                    let emergencyCoordinates = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    
                    let distance = driverCoordinates.distance(from: emergencyCoordinates)
                    if distance <= 5000 { // 🚖 Notify drivers within 5km
                        let driverId = doc.documentID
                        self?.sendPushNotification(to: driverId, title: "🚨 Emergency Alert", message: "Nearby rider needs urgent help!")
                    }
                }
            }
        }
            
        
    }
}
extension EmergencySystem {
    private func notifyEmergencyContacts(userId: String, location: CLLocationCoordinate2D?) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return } // Ensure self exists before proceeding

            guard let data = snapshot?.data(), error == nil else {
                print("❌ Error fetching user emergency contacts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let contacts = data["emergencyContacts"] as? [String] { // List of emergency contact numbers
                for contact in contacts {
                    self.sendEmergencySMS(to: contact, location: location) // Explicitly use `self`
                }
            }
        }
    
}

    private func sendEmergencySMS(to phoneNumber: String, location: CLLocationCoordinate2D?) {
        let message = "🚨 EMERGENCY ALERT! Your contact needs urgent help. Location: \(location?.latitude ?? 0), \(location?.longitude ?? 0)."

        print("📲 Sending SMS to \(phoneNumber): \(message)")
        
        // Integrate Twilio API here
        // Example:
        // TwilioAPI.sendSMS(to: phoneNumber, message: message)
    }
}
extension EmergencySystem {
    private func triggerUserAlert() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("EmergencyTriggered"), object: nil)
        }

        // ✅ Auto-dial 911 after 5 seconds (optional)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.autoCallEmergency() // Explicitly use `self`
        }
    }


    private func autoCallEmergency() {
        let phoneNumber = "tel://911"
        if let url = URL(string: phoneNumber), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
import FirebaseMessaging

extension EmergencySystem {
    private func sendPushNotification(to userId: String, title: String, message: String) {
        let payload: [String: Any] = [
            "to": "/topics/\(userId)", // Subscribed topic for each user
            "notification": [
                "title": title,
                "body": message
            ]
        ]

        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=YOUR_FIREBASE_SERVER_KEY", forHTTPHeaderField: "Authorization") // Replace with your Firebase server key
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Push notification sent!")
            }
        }.resume()
    }
}
