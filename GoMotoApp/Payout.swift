//
//  Payout.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/21/25.
//

import Foundation
import SwiftUI

import FirebaseFirestore

struct Payout: Identifiable, Codable {
    let id: String
    let amount: Double
    let date: Date
    let status: String

    // Correct initializer for Firestore documents
    init(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        self.id = doc.documentID
        self.amount = data["amount"] as? Double ?? 0.0
        self.date = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.status = data["status"] as? String ?? "unknown"
    }
}
