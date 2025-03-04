//
//  AdminViewModel.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore

class AdminViewModel: ObservableObject {
    @Published var totalEarnings: Double = 0.0
    @Published var pendingPayouts: [Payout] = []
   
    @Published var isProcessingPayouts = false
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    @Published var transactionHistory: [AppTransaction] = []

    private let db = Firestore.firestore()
    
    init() {
        fetchPaymentData()
    }

    func fetchPaymentData() {
        Task {
            await fetchTotalEarnings()
            await fetchPendingPayouts()
            await fetchTransactionHistory()
        }
    }
    
    private func fetchTotalEarnings() async {
        do {
            let doc = try await db.collection("admin").document("earnings").getDocument()
            self.totalEarnings = doc.data()?["totalEarnings"] as? Double ?? 0.0
        } catch {
            print("Error fetching earnings: \(error)")
        }
    }
    
    private func fetchPendingPayouts() async {
        do {
            let snapshot = try await db.collection("payouts")
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            self.pendingPayouts = snapshot.documents.map { Payout(doc: $0) } // ✅ Corrected
        } catch {
            print("Error fetching pending payouts: \(error)")
        }
    }

    private func fetchTransactionHistory() async {
        do {
            let snapshot = try await db.collection("transactions")
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
                .getDocuments()
            self.transactionHistory = snapshot.documents.map { AppTransaction(from: $0) }
        } catch {
            print("Error fetching transaction history: \(error)")
        }
    }
    
    func processWeeklyPayouts() {
        guard !pendingPayouts.isEmpty else { return }
        isProcessingPayouts = true
        
        let batch = db.batch()
        for payout in pendingPayouts {
            let payoutRef = db.collection("payouts").document(payout.id)
            batch.updateData(["status": "completed"], forDocument: payoutRef)
        }
        
        batch.commit { error in
            DispatchQueue.main.async {
                self.isProcessingPayouts = false
                if let error = error {
                    self.alertMessage = "Failed to process payouts: \(error.localizedDescription)"
                } else {
                    self.alertMessage = "Payouts processed successfully!"
                    self.pendingPayouts.removeAll()
                }
                self.showAlert = true
            }
        }
    }
}
