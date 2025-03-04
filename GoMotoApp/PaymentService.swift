//
//  PaymentService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import SwiftUI
import StripePaymentSheet

class PaymentService: ObservableObject {
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var isProcessing = false

    func preparePaymentSheet(orderAmount: Double, currency: String = "usd") {
        isProcessing = true
        let backendURL = "https://us-central1-gomoto-c9e9f.cloudfunctions.net/createPaymentIntent"

        let parameters: [String: Any] = [
            "amount": Int(orderAmount * 100), // Convert to cents
            "currency": currency
        ]

        var request = URLRequest(url: URL(string: backendURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isProcessing = false }
            guard let data = data, error == nil else { return }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let clientSecret = json?["clientSecret"] as? String ?? ""

                DispatchQueue.main.async {
                    var config = PaymentSheet.Configuration()
                    config.merchantDisplayName = "GoMotoApp"
                    config.allowsDelayedPaymentMethods = false

                    PaymentSheet.FlowController.create(paymentIntentClientSecret: clientSecret, configuration: config) { result in
                        switch result {
                        case .failure(let error):
                            print("Error creating FlowController: \(error)")
                        case .success(let flowController):
                            self.paymentSheetFlowController = flowController
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }
}
