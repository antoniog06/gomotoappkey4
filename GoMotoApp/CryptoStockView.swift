//
//  CryptoStockView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import SwiftUI
import Charts
import FirebaseFirestore



// MARK: - Crypto & Stocks Investment View
struct CryptoStockView: View {
    @StateObject private var binanceService = BinanceService()
    private let db = Firestore.firestore()
    @ObservedObject var viewModel:  CryptoViewModel
    @State private var selectedInvestment = "Crypto"
    @State private var cryptoBalance: Double = 0.0
    @State private var stockBalance: Double = 0.0
    let cryptoSymbols = ["BTC", "ETH", "BNB", "XRP", "DOGE", "SHIB"]
    // Declare State variables in the parent view
    @State private var selectedCrypto: String = "SHIB"
    @State private var prices: [KlineData] = []
    @State private var selectedTimeframe: String = "1D"
    @State private var showCandlestick: Bool = false
    @State private var isLoading: Bool = false

   

    var body: some View {
        NavigationView {
            VStack {
                Text("💰 Crypto & Stocks")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationStack { // Updated to NavigationStack for iOS 16+ (modern navigation)
                    List {
                        // Navigate to CryptoTradeView for trading
                        NavigationLink( destination: CryptoTradeView(viewModel: viewModel)) {
                            Text("Trade Cryptocurrencies")
                        }
                        
                        // ✅ Corrected NavigationLink
                        NavigationLink(destination: CryptoChartView(
                            selectedCrypto: $selectedCrypto,
                            prices: $prices,
                            selectedTimeframe: $selectedTimeframe,
                            isLoading: $isLoading,
                            showCandlestick: $showCandlestick
                           
                        )) {
                            Text("Invest in Crypto")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                        
                    .navigationTitle("Crypto Dashboard")
                }
                .padding()
                
                Text("📈 Invest in Crypto")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Investment Dashboard")
        }
        
        // Investment Type Picker
        Picker(selection: $selectedInvestment, label: Text("Investment Type")) {
            Text("Crypto").tag("Crypto")
            Text("Stocks").tag("Stocks")
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        
        if selectedInvestment == "Crypto" {
            // 🔥 Live Crypto Market View
            List {
                ForEach(cryptoSymbols, id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                            .font(.headline)
                        Spacer()
                        if let price = binanceService.cryptoPrices[symbol] {
                            Text("$\(String(format: "%.2f", price))")
                                .foregroundColor(.green)
                        } else {
                            ProgressView()
                        }
                    }
                }
            }
            
            // 🔥 Crypto Balance & Actions
            VStack {
                Text("Your Crypto Balance: \(cryptoBalance, specifier: "%.2f") USD")
                    .font(.title2)
                
                HStack {
                    Button("Buy Crypto") {
                        CryptoService().buyCrypto(userID: "currentUserID", amountUSD: 100, cryptoType: "BTC")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Stake Crypto") {
                        stakeCrypto(userID: "currentUserID", amount: 0.05, cryptoType: "ETH")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        } else {
            // 🔥 Stock Market View
            VStack {
                Text("Your Stock Balance: \(stockBalance, specifier: "%.2f") USD")
                    .font(.title2)
                
                HStack {
                    Button("Buy Stocks") {
                        buyStock(userID: "currentUserID", stockSymbol: "AAPL", shares: 2)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Auto-Invest") {
                        autoInvest(userID: "currentUserID", depositAmount: 500)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            }
            .padding()
            .navigationTitle("💰 Crypto & Stocks")
            .onAppear {
                for symbol in cryptoSymbols {
                    binanceService.fetchCryptoPrice(for: symbol)
                }
            }
        }
    }

    // MARK: - Stock Trading Functions
    func buyStock(userID: String, stockSymbol: String, shares: Int) {
        let stockPrice = getStockPrice(stockSymbol: stockSymbol)
        let totalCost = Double(shares) * stockPrice
        let portfolioRef = db.collection("stock_portfolios").document(userID)

        portfolioRef.updateData([
            "holdings.\(stockSymbol)": FieldValue.increment(Double(shares)),
            "transactions": FieldValue.arrayUnion([
                ["type": "buy", "amount": shares, "stock": stockSymbol, "date": Timestamp(date: Date())]
            ])
        ]) { error in
            if let error = error {
                print("Error buying stock: \(error.localizedDescription)")
            } else {
                print("Successfully bought \(shares) shares of \(stockSymbol)!")
            }
        }
    }

    func autoInvest(userID: String, depositAmount: Double) {
        let portfolioAllocation = getAIPortfolioAllocation()
        let investRef = db.collection("auto_investments").document(userID)

        investRef.updateData([
            "totalInvested": FieldValue.increment(depositAmount),
            "portfolio": portfolioAllocation
        ]) { error in
            if let error = error {
                print("Error auto-investing: \(error.localizedDescription)")
            } else {
                print("Auto-investment successful!")
            }
        }
    }

    func getAIPortfolioAllocation() -> [String: Any] {
        return [
            "stocks": ["AAPL": 30, "TSLA": 20, "NVDA": 50],
            "crypto": ["BTC": 40, "ETH": 60]
        ]
    }

    // MARK: - Crypto Staking & Rewards
    func stakeCrypto(userID: String, amount: Double, cryptoType: String) {
        let stakingRef = db.collection("staking").document(userID)

        stakingRef.updateData([
            "stakedAssets.\(cryptoType)": FieldValue.increment(amount)
        ]) { error in
            if let error = error {
                print("Error staking crypto: \(error.localizedDescription)")
            } else {
                print("Successfully staked \(amount) \(cryptoType)")
            }
        }
    }

    func calculateStakingRewards() {
        let stakingAPY = ["ETH": 0.07, "SOL": 0.10]
        db.collection("staking").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching staking data: \(error.localizedDescription)")
                return
            }
            for document in snapshot!.documents {
                let userID = document.documentID
                var updates: [String: Any] = [:]

                for (crypto, apy) in stakingAPY {
                    let stakedAmount = document.data()["stakedAssets.\(crypto)"] as? Double ?? 0.0
                    let dailyReward = (stakedAmount * apy) / 365
                    updates["rewards.totalEarned"] = FieldValue.increment(dailyReward)
                }
                db.collection("staking").document(userID).updateData(updates)
            }
        }
    }

    // MARK: - AI Investment Advice
    func getInvestmentAdvice(userID: String) -> String {
        let userRiskLevel = getUserRiskLevel(userID: userID)
        switch userRiskLevel {
        case "high":
            return "Invest in high-growth stocks like Tesla & Ethereum."
        case "medium":
            return "Invest in stable stocks like Apple & Bitcoin."
        default:
            return "Invest in safe assets like bonds & gold."
        }
    }

    func getUserRiskLevel(userID: String) -> String {
        return "medium"
    }

    // MARK: - Mock Price Fetching
    func getStockPrice(stockSymbol: String) -> Double {
        return 150.0 // Example AAPL price
    }
}

#Preview {
    CryptoStockView(viewModel: CryptoViewModel())
}







/*import SwiftUI
import Charts
import FirebaseFirestore




// MARK: - Crypto & Stocks Investment View
struct CryptoStockView: View {
    @StateObject private var binanceService = BinanceService()
    private let db = Firestore.firestore()
    @State private var viewModel = CryptoViewModel() // Use @ObservedObject instead of @Binding for viewModel
    @State private var selectedInvestment = "Crypto"
    @State private var cryptoBalance: Double = 0.0
    @State private var stockBalance: Double = 0.0
    let cryptoSymbols = ["BTC", "ETH", "BNB", "XRP", "DOGE"]

    var body: some View {
        NavigationView {
            VStack {
                Text("💰 Crypto & Stocks")
                    .font(.largeTitle)
                    .fontWeight(.bold)

               NavigationStack { // Updated to NavigationStack for iOS 16+ (modern navigation)
                                 List {
                                     // Navigate to CryptoTradeView for trading
                                     NavigationLink(destination: CryptoTradeView(viewModel: viewModel)) {
                                         Text("Trade Cryptocurrencies")
                                     }
                                     
                                     // Navigate to CryptoChartView for charting
                    /*    NavigationLink(destination: CryptoChartView(
                            selectedCrypto: $viewModel.selectedCrypto,
                            prices: $viewModel.prices,
                            selectedTimeframe: $viewModel.selectedTimeframe,
                            showCandlestick: $viewModel.showCandlestick,
                            isLoading: $viewModel.isLoading
                        )) {
                            Text("View Crypto Chart")
                        }*/
                    }
                    .navigationTitle("Crypto Dashboard")
                }
                .padding()
                
                Text("📈 Invest in Crypto")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Investment Dashboard") // ✅ Adds a navigation bar title
        }
        
        // Investment Type Picker
        Picker(selection: $selectedInvestment, label: Text("Investment Type")) {
            Text("Crypto").tag("Crypto")
            Text("Stocks").tag("Stocks")
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        
        if selectedInvestment == "Crypto" {
            // 🔥 Live Crypto Market View
            List {
                ForEach(cryptoSymbols, id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                            .font(.headline)
                        Spacer()
                        if let price = binanceService.cryptoPrices[symbol] {
                            Text("$\(String(format: "%.2f", price))")
                                .foregroundColor(.green)
                        } else {
                            ProgressView()
                        }
                    }
                }
            }
            
            // 🔥 Crypto Balance & Actions
            VStack {
                Text("Your Crypto Balance: \(cryptoBalance, specifier: "%.2f") USD")
                    .font(.title2)
                
                HStack {
                    Button("Buy Crypto") {
                        CryptoService().buyCrypto(userID: "currentUserID", amountUSD: 100, cryptoType: "BTC")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Stake Crypto") {
                        stakeCrypto(userID: "currentUserID", amount: 0.05, cryptoType: "ETH")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        } else {
            // 🔥 Stock Market View
            VStack {
                Text("Your Stock Balance: \(stockBalance, specifier: "%.2f") USD")
                    .font(.title2)
                
                HStack {
                    Button("Buy Stocks") {
                        buyStock(userID: "currentUserID", stockSymbol: "AAPL", shares: 2)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Auto-Invest") {
                        autoInvest(userID: "currentUserID", depositAmount: 500)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            }
            .padding()
            .navigationTitle("💰 Crypto & Stocks")
            .onAppear {
                for symbol in cryptoSymbols {
                    binanceService.fetchCryptoPrice(for: symbol)
                }
            }
        }
    }

    // MARK: - Stock Trading Functions
    func buyStock(userID: String, stockSymbol: String, shares: Int) {
        let stockPrice = getStockPrice(stockSymbol: stockSymbol)
        let totalCost = Double(shares) * stockPrice
        let portfolioRef = db.collection("stock_portfolios").document(userID)

        portfolioRef.updateData([
            "holdings.\(stockSymbol)": FieldValue.increment(Double(shares)),
            "transactions": FieldValue.arrayUnion([
                ["type": "buy", "amount": shares, "stock": stockSymbol, "date": Timestamp(date: Date())]
            ])
        ]) { error in
            if let error = error {
                print("Error buying stock: \(error.localizedDescription)")
            } else {
                print("Successfully bought \(shares) shares of \(stockSymbol)!")
            }
        }
    }

    func autoInvest(userID: String, depositAmount: Double) {
        let portfolioAllocation = getAIPortfolioAllocation()
        let investRef = db.collection("auto_investments").document(userID)

        investRef.updateData([
            "totalInvested": FieldValue.increment(depositAmount),
            "portfolio": portfolioAllocation
        ]) { error in
            if let error = error {
                print("Error auto-investing: \(error.localizedDescription)")
            } else {
                print("Auto-investment successful!")
            }
        }
    }

    func getAIPortfolioAllocation() -> [String: Any] {
        return [
            "stocks": ["AAPL": 30, "TSLA": 20, "NVDA": 50],
            "crypto": ["BTC": 40, "ETH": 60]
        ]
    }

    // MARK: - Crypto Staking & Rewards
    func stakeCrypto(userID: String, amount: Double, cryptoType: String) {
        let stakingRef = db.collection("staking").document(userID)

        stakingRef.updateData([
            "stakedAssets.\(cryptoType)": FieldValue.increment(amount)
        ]) { error in
            if let error = error {
                print("Error staking crypto: \(error.localizedDescription)")
            } else {
                print("Successfully staked \(amount) \(cryptoType)")
            }
        }
    }

    func calculateStakingRewards() {
        let stakingAPY = ["ETH": 0.07, "SOL": 0.10]
        db.collection("staking").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching staking data: \(error.localizedDescription)")
                return
            }
            for document in snapshot!.documents {
                let userID = document.documentID
                var updates: [String: Any] = [:]

                for (crypto, apy) in stakingAPY {
                    let stakedAmount = document.data()["stakedAssets.\(crypto)"] as? Double ?? 0.0
                    let dailyReward = (stakedAmount * apy) / 365
                    updates["rewards.totalEarned"] = FieldValue.increment(dailyReward)
                }
                db.collection("staking").document(userID).updateData(updates)
            }
        }
    }

    // MARK: - AI Investment Advice
    func getInvestmentAdvice(userID: String) -> String {
        let userRiskLevel = getUserRiskLevel(userID: userID)
        switch userRiskLevel {
        case "high":
            return "Invest in high-growth stocks like Tesla & Ethereum."
        case "medium":
            return "Invest in stable stocks like Apple & Bitcoin."
        default:
            return "Invest in safe assets like bonds & gold."
        }
    }

    func getUserRiskLevel(userID: String) -> String {
        return "medium"
    }

    // MARK: - Mock Price Fetching
    func getStockPrice(stockSymbol: String) -> Double {
        return 150.0 // Example AAPL price
    }
}
*/

