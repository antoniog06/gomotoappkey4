//
//  Transaction.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import Firebase
import FirebaseFirestore
import Foundation
import SwiftUI

struct AppTransaction: Identifiable, Codable {
    let id: String
    let description: String
    let amount: Double
    let date: Date
    let isCredit: Bool
    
    // Computed properties
    var adminFee: Double {
        return amount > 50 ? max(2, amount * 0.05) : 2
    }
    
    var driverEarnings: Double {
        return amount - adminFee
    }
    
    // Date formatter for UI display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Default initializer for Firestore compatibility
    init(from document: QueryDocumentSnapshot) {
        let data = document.data()
        self.id = document.documentID
        self.description = data["description"] as? String ?? "Unknown Transaction"
        self.amount = data["amount"] as? Double ?? 0.0
        self.date = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.isCredit = data["isCredit"] as? Bool ?? false
    }
    
    // Firestore decoder (recommended for automatic decoding)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.description = try container.decode(String.self, forKey: .description)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.date = try container.decode(Date.self, forKey: .date)
        self.isCredit = try container.decode(Bool.self, forKey: .isCredit)
    }
  

    func fetchTransactions(completion: @escaping ([AppTransaction]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("transactions").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching transactions: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let transactions: [AppTransaction] = documents.compactMap { doc in
                try? doc.data(as: AppTransaction.self)
            }
            completion(transactions)
        }
    }
}

/*import Firebase
import Foundation
import SwiftUI

struct AppTransaction: Identifiable, Codable {
    let id: String
    let description: String
    let amount: Double
    let date: Date
    let isCredit: Bool
   // let adminFee: Double
  //  let driverEarnings: Double

   
    var adminFee: Double {
        return amount > 50 ? max(2, amount * 0.05) : 2
    }
    
    var driverEarnings: Double {
        return amount - adminFee
    }

    init(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        self.id = doc.documentID
        self.description = data["description"] as? String ?? "Unknown Transaction"
        self.amount = data["amount"] as? Double ?? 0.0
        self.date = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.isCredit = data["isCredit"] as? Bool ?? false
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
   
}*/
