//
//  WalletViewModel.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import FirebaseFirestore
import SwiftUI

class WalletViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var transactions: [WalletTransaction] = []


    private let db = Firestore.firestore()

    func fetchWalletData(userID: String) {
        db.collection("wallets").document(userID).getDocument { [weak self] (document, error) in
            guard let self = self else { return } // Safely unwrapping self
            if let document = document, document.exists {
                let balance = document.data()?["balance"] as? Double ?? 0.0
                print("User balance: \(balance)")
            }
        }
    }
    func saveTransaction(transaction: AppTransaction) {
        let transactionData: [String: Any] = [
            "description": transaction.description,
            "amount": transaction.amount,
            "timestamp": Timestamp(date: transaction.date),
            "isCredit": transaction.isCredit,
            "adminFee": transaction.adminFee,
            "driverEarnings": transaction.driverEarnings
        ]

        db.collection("transactions").document(transaction.id).setData(transactionData) { error in
            if let error = error {
                print("Error saving transaction: \(error.localizedDescription)")
            } else {
                print("Transaction saved successfully!")
            }
        }
    }
}
struct WalletTransaction: Identifiable, Codable {
    let id: String
    let type: String // "send" or "receive"
    let amount: Double
    let date: Date
}
/*struct Transaction: Identifiable , Codable {
    let id = UUID()
    let type: String
    let amount: Double
    let otherUser: String
    let date: Date

    init(data: [String: Any]) {
        self.type = data["type"] as? String ?? "unknown"
        self.amount = data["amount"] as? Double ?? 0.0
        self.otherUser = data["to"] as? String ?? data["from"] as? String ?? "unknown"
        self.date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
    }
}*/


/*func fetchWalletData(userID: String) {
    db.collection("wallets").document(userID).addSnapshotListener { document, error in
        if let document = document, document.exists {
            self.balance = document.data()?["balance"] as? Double ?? 0.0
            self.transactions = (document.data()?["transactions"] as? [[String: Any]])?.map { Transaction(data: $0) } ?? []
        }
    }
}*/
