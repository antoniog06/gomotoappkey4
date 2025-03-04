//
//  PaymentView.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
//

import StripePaymentSheet
import Stripe
import FirebaseAuth
import SwiftUI
import Firebase
import FirebaseFirestore

struct PaymentView: View {
    @State private var balance: Double = 0.0
    @State private var paymentMethodParams: STPPaymentMethodParams?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var paymentMethods: [String] = []
    @State private var transactionHistory: [Transaction] = []
    @State private var selectedPaymentMethod: String = "Credit Card"
    @State private var isDriver: Bool = false
    @State private var showPayoutAlert: Bool = false
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentSheetFlowController: PaymentSheet.FlowController?
    @State private var showPaymentSheet = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Payments Screen")
                    .font(.largeTitle)
                    .bold()
                
                Text("Total Earnings: $\(balance, specifier: "%.2f")")
                    .font(.headline)
                    .padding()
             /*   Button(action: requestPayout) {
                    Text("Request Payout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                    
                }*/
                
                Text("Payments")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                if isDriver {
                    earningsSection
                } else {
                    userPaymentSection
                }
                
                transactionHistorySection
                
                Spacer()
               
                                // Checkout Button
                                Button("Checkout") {
                                    preparePaymentSheet()
                                }
                                .disabled(isProcessing)
                                .padding()
                                
                                // Pay Now Button (Only if FlowController is Ready)
                                if let paymentSheetFlowController = paymentSheetFlowController {
                                    Button(action: presentPaymentSheet) {
                                        Text(isProcessing ? "Processing..." : "Pay Now")
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .disabled(paymentSheetFlowController == nil)
                                    .padding()
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .onAppear { fetchPaymentDetails() }
                            .alert(isPresented: $showPayoutAlert) {
                                Alert(
                                    title: Text("Payout Requested"),
                                    message: Text("Your payout request has been submitted."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                            .navigationTitle("Payments")
                        }
                    }
                }

                // MARK: - 🔹 Prepare PaymentSheet
extension PaymentView {
    private func preparePaymentSheet() {
        isProcessing = true
        let backendURL = "https://us-central1-gomoto-c9e9f.cloudfunctions.net/createPaymentIntent"
        
        var request = URLRequest(url: URL(string: backendURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "amount": 5000, // Example: $50.00
            "currency": "usd"
        ])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { isProcessing = false }
            guard let data = data, error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let clientSecret = json["clientSecret"] as? String {
                    
                    DispatchQueue.main.async {
                        PaymentSheet.FlowController.create(
                            paymentIntentClientSecret: clientSecret,
                            configuration: PaymentSheet.Configuration(),
                            completion: { result in
                                switch result {
                                case .success(let flowController):
                                    self.paymentSheetFlowController = flowController
                                case .failure(let error):
                                    self.alertMessage = "Error: \(error.localizedDescription)"
                                    self.showAlert = true
                                }
                            }
                        )
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }
    
}
    
// MARK: - 🔹 Present Payment Sheet




extension PaymentView {
    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        
        // Get the root view controller correctly
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first?.rootViewController {
            
            // Present the Payment Sheet
            paymentSheet.present(from: rootViewController) { paymentResult in
                DispatchQueue.main.async {
                    switch paymentResult {
                    case .completed:
                        print("✅ Payment successful!")
                    case .failed(let error):
                        print("❌ Payment failed: \(error.localizedDescription)")
                    case .canceled:
                        print("⚠️ Payment canceled.")
                    }
                }
            }
        }
    }
    
    
    
    
    
    // MARK: - 🔹 Request Payout Function
    // MARK: - 🔹 Request Payout Function
    private func requestPayout(driverID: String, amount: Double) {
        guard amount > 0 else {
            print("⚠️ Payout amount must be greater than zero.")
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        
        // 🔹 Fetch Driver's Stripe Account ID from Firestore
        db.collection("drivers").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let stripeAccountId = data["stripeAccountId"] as? String {
                let payoutAmount = Int(amount * 100) // Convert dollars to cents
                
                let payoutRequest: [String: Any] = [
                    "driverID": driverID,
                    "amount": payoutAmount,
                    "currency": "usd",
                    "destination": stripeAccountId,
                    "method": "instant"
                ]
                
                // 🔹 Firebase Cloud Function URL for Payouts
                let url = URL(string: "https://us-central1-gomoto-c9e9f.cloudfunctions.net/createPayout")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: payoutRequest)
                
                // 🔹 Execute Payout Request
                URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Payout Error: \(error.localizedDescription)")
                            return
                        }
                        
                        if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let success = jsonResponse["success"] as? Bool, success {
                            print("✅ Payout requested successfully!")
                            
                            // 🔹 Log Transaction in Firestore Wallets Collection
                            addTransactionToWallet(driverID: driverID, amount: amount, type: "withdraw", metadata: ["to": "bank"])
                            
                            // 🔹 Reset Driver's Earnings in Firestore After Successful Payout
                            db.collection("drivers").document(userId).updateData(["earnings": 0.0])
                            
                            // 🔹 Show confirmation alert
                            showPayoutAlert = true
                            balance = 0.0
                        } else {
                            print("⚠️ Payout request failed: \(String(describing: response))")
                        }
                    }
                }.resume()
            } else {
                print("⚠️ No Stripe Account ID found for driver.")
            }
        }
    }
    func addTransactionToWallet(driverID: String, amount: Double, type: String, metadata: [String: Any] = [:]) {
        let walletRef = Firestore.firestore().collection("wallets").document(driverID)
        
        let transactionData: [String: Any] = [
            "amount": amount,
            "date": Timestamp(date: Date()),
            "type": type
        ].merging(metadata) { (_, new) in new }

        walletRef.updateData([
            "transactions": FieldValue.arrayUnion([transactionData])
        ]) { error in
            if let error = error {
                print("⚠️ Failed to update transactions: \(error.localizedDescription)")
            } else {
                print("✅ Transaction successfully added to wallet!")
            }
        }
    }
}

extension PaymentView {
    private func addPaymentMethod() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let backendURL = "https://us-central1-gomoto-c9e9f.cloudfunctions.net/createPaymentIntent"
        let parameters: [String: Any] = [
            "amount": 5000, // Example: $50.00
            "currency": "usd"
        ]
        
        var request = URLRequest(url: URL(string: backendURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let clientSecret = json["clientSecret"] as? String {
                
                DispatchQueue.main.async {
                    // ✅ Fix: Add `PaymentSheet.Configuration`
                    var config = PaymentSheet.Configuration()
                    config.merchantDisplayName = "GoMotoApp"
                    config.allowsDelayedPaymentMethods = true
                    
                    self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                    self.showPaymentSheet = true
                }
            }
        }.resume()
    }
}



// MARK: - 🔹 Handle Payment Result
extension PaymentView {
    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            print("Payment successful!")
        case .failed(let error):
            print("Payment failed: \(error.localizedDescription)")
        case .canceled:
            print("Payment canceled.")
        }
    }
}

// MARK: - 🔹 Driver Earnings Section
extension PaymentView {
    private var earningsSection: some View {
        VStack(spacing: 10) {
            Text("Total Earnings")
                .font(.headline)
            Text("$\(balance, specifier: "%.2f")")
                .font(.title)
                .bold()
                .foregroundColor(.blue)

          /*  Button(action: requestPayout) {
                Text("Request Payout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }*/
            .padding(.horizontal)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(radius: 5))
    }
}

// MARK: - 🔹 User Payment Methods
extension PaymentView {
    private var userPaymentSection: some View {
        VStack(spacing: 10) {
            Text("Saved Payment Methods")
                .font(.headline)

            Picker("Payment Method", selection: $selectedPaymentMethod) {
                ForEach(paymentMethods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Button(action: addPaymentMethod) {
                Text("Add Payment Method")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(radius: 5))
    }
}

// MARK: - 🔹 Transaction History
extension PaymentView {
    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transaction History")
                .font(.headline)

            if transactionHistory.isEmpty {
                Text("No transactions available")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding()
            } else {
                List(transactionHistory) { transaction in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transaction.description)
                            Text(transaction.date, style: .date)
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        Spacer()
                        Text("$\(transaction.amount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(transaction.isCredit ? .green : .red)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .padding()
    }
}

// MARK: - 🔹 Firestore Integration
extension PaymentView {
    private func fetchPaymentDetails() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                isDriver = data["userType"] as? String == "driver"
                balance = data["earnings"] as? Double ?? 0.0
                paymentMethods = data["paymentMethods"] as? [String] ?? ["Credit Card", "PayPal", "Apple Pay"]

                fetchTransactionHistory(for: userId)
            }
        }
    }

    private func fetchTransactionHistory(for userId: String) {
        db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, _ in
                self.transactionHistory = snapshot?.documents.map { Transaction(doc: $0) } ?? []
            }
    }
}

// MARK: - 🔹 Transaction Model
struct Transaction: Identifiable {
    let id: String
    let description: String
    let amount: Double
    let date: Date
    let isCredit: Bool

    init(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        self.id = doc.documentID
        self.description = data["description"] as? String ?? "Unknown Transaction"
        self.amount = data["amount"] as? Double ?? 0.0
        self.date = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.isCredit = data["isCredit"] as? Bool ?? false
    }
}










    /*    private func requestPayout() {
            guard balance > 0 else { return }
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            db.collection("drivers").document(userId).getDocument { snapshot, _ in
                if let data = snapshot?.data(), let stripeAccountId = data["stripeAccountId"] as? String {
                    let payoutAmount = balance * 100 // Convert to cents
                    
                    let payoutRequest = [
                        "amount": payoutAmount,
                        "currency": "usd",
                        "destination": stripeAccountId,
                        "method": "instant"
                    ] as [String: Any]
                    
                    var request = URLRequest(url: URL(string: "https://us-central1-gomoto-c9e9f.cloudfunctions.net/createPayout")!)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try? JSONSerialization.data(withJSONObject: payoutRequest)
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("Payout Error: \(error.localizedDescription)")
                            } else {
                                showPayoutAlert = true
                                balance = 0.0
                                db.collection("drivers").document(userId).updateData(["earnings": 0.0])
                            }
                        }
                    }.resume()
                }
            }
        }
    }*/


    
    




