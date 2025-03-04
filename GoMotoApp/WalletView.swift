//
//  WalletView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import SwiftUI

struct WalletView: View {
    @State private var balance: Double = 100.50
    @State private var amountToSend = ""
    @StateObject var viewModel = WalletViewModel()

    var body: some View {
        VStack {
            Text("Your Balance: \(viewModel.balance)")
                .font(.largeTitle)
                .padding()
            
            List(viewModel.transactions) { transaction in
                HStack {
                    Text("\(transaction.type) - \(transaction.amount) " )
                    Spacer()
                    Text("$\(transaction.amount, specifier: "%.2f")")
                        .foregroundColor(transaction.type == "send" ? .red : .green)
                }
            }
            

            TextField("Enter Amount", text: $amountToSend)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                // Call sendMoney function here
                print("Send Money")
            }) {
                Text("Send Money")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Button(action: {
                // Call withdrawToBank function here
                print("Withdraw Money")
            }) {
                Text("Withdraw to Bank")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Wallet")
        .onAppear {
            viewModel.fetchWalletData(userID: "currentUserID")
        }
    }
    func sendMoney(fromUser: String, toUser: String, amount: Double, currency: String = "usd") {
        let parameters: [String: Any] = [
            "amount": Int(amount * 100),
            "currency": currency,
            "destination": toUser
        ]

        let url = URL(string: "https://api.stripe.com/v1/transfers")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("sk_test_51Iq9ruJe5shBun0GpRJAy7HTi61CPrprbmSoMdgaZiGyw2m2bQN10FSUWwHRsByrCcNGkm8NBvRryE79cJKF4rNG0017XImhCg", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Transfer failed: \(error.localizedDescription)")
            } else {
                print("Transfer successful!")
            }
        }.resume()
    }
    
}
/*import SwiftUI

// MARK: - Wallet View
struct WalletView: View {
    @State private var fiatBalance: Double = 1000.00
    @State private var cryptoHoldings: [String: Double] = [
        "BTC": 0.05, "ETH": 1.2, "BNB": 3.5
    ]
    @StateObject private var binanceService = BinanceService()

    var body: some View {
        NavigationView {
            VStack {
                // 💰 Fiat Balance Display
                Text("Wallet Balance")
                    .font(.title)
                    .bold()
                
                Text("$\(String(format: "%.2f", fiatBalance))")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .bold()
                    .padding(.bottom)

                // 📈 Crypto Holdings List
                List {
                    ForEach(cryptoHoldings.keys.sorted(), id: \.self) { symbol in
                        HStack {
                            Text(symbol)
                                .font(.headline)
                            Spacer()
                            if let price = binanceService.cryptoPrices[symbol] {
                                let value = (cryptoHoldings[symbol] ?? 0) * price
                                Text("\(cryptoHoldings[symbol]!, specifier: "%.4f") • $\(String(format: "%.2f", value))")
                                    .foregroundColor(.blue)
                            } else {
                                ProgressView()
                            }
                        }
                    }
                }
                
                // 🛒 Buy & Sell Buttons
                HStack {
                    Button(action: {
                        // Implement Buy Action
                    }) {
                        Text("Buy Crypto")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Implement Sell Action
                    }) {
                        Text("Sell Crypto")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .onAppear {
                for symbol in cryptoHoldings.keys {
                    binanceService.fetchCryptoPrice(for: symbol)
                }
            }
            .navigationTitle("Wallet 💰")
        }
    }
}*/




   
      
