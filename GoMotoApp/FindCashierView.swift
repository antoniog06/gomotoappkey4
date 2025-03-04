//
//  FindCashierView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//
import SwiftUI
import FirebaseFirestore
import CoreLocation
import LocalAuthentication

struct FindCashierView: View {
    @State private var cashiers: [Cashier] = []
    let locator = CashierLocator()
    @State private var db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Find a Cashier Near You")
                .font(.title)
                .padding()

            List(cashiers) { cashier in
                Button(action: {
                    CashOutService().sendMoneyToCashier(recipientID: "currentUserID", cashierID: cashier.id, amount: 99.0)
                }) {
                    VStack(alignment: .leading) {
                        Text("Cashier ID: \(cashier.userID)")
                        Text("Available Cash: $\(cashier.availableCash, specifier: "%.2f")")
                    }
                }
            }
        }
        .onAppear {
            locator.findNearbyCashiers(userLocation: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)) { foundCashiers in
                self.cashiers = foundCashiers
            }
        }
    }
    func rateUser(userID: String, reviewerID: String, rating: Int, comment: String) {
        let ratingRef = db.collection("userRatings").document(userID)

        ratingRef.updateData([
            "reviews": FieldValue.arrayUnion([
                ["reviewerID": reviewerID, "stars": rating, "comment": comment]
            ])
        ]) { error in
            if let error = error {
                print("Error updating rating: \(error.localizedDescription)")
            } else {
                print("Rating submitted successfully!")
            }
        }
    }
   

    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authorize Payment") { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
    func processCryptoPayment(amount: Double, currency: String) {
        let parameters: [String: Any] = [
            "amount": Int(amount * 100),
            "currency": currency,
            "payment_method_types": ["crypto"]
        ]

        let url = URL(string: "https://api.stripe.com/v1/payment_intents")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer YOUR_STRIPE_SECRET_KEY", forHTTPHeaderField: "Authorization")

        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Crypto transaction failed: \(error.localizedDescription)")
            } else {
                print("Crypto transaction successful!")
            }
        }.resume()
    }
    func convertCurrency(from: String, to: String, amount: Double, completion: @escaping (Double) -> Void) {
        let url = URL(string: "https://api.exchangeratesapi.io/latest?base=\(from)&symbols=\(to)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let exchangeRates = try? JSONDecoder().decode([String: Double].self, from: data),
               let rate = exchangeRates[to] {
                let convertedAmount = amount * rate
                completion(convertedAmount)
            }
        }.resume()
    }
    func requestLoan(borrowerID: String, amount: Double, interestRate: Double, dueDate: String) {
        let loanData: [String: Any] = [
            "borrowerID": borrowerID,
            "amount": amount,
            "interestRate": interestRate,
            "dueDate": dueDate,
            "status": "pending"
        ]

        db.collection("loans").addDocument(data: loanData) { error in
            if let error = error {
                print("Error requesting loan: \(error.localizedDescription)")
            } else {
                print("Loan request submitted!")
            }
        }
    }
    func createVirtualCard(userID: String) {
        let url = URL(string: "https://api.stripe.com/v1/issuing/cards")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer YOUR_STRIPE_SECRET_KEY", forHTTPHeaderField: "Authorization")

        let body = "cardholder=\(userID)&currency=usd&type=virtual"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Virtual card creation failed: \(error.localizedDescription)")
            } else {
                print("Virtual card created successfully!")
            }
        }.resume()
    }
}
