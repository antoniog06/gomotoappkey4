//
//  CryptoDashboardView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//

import SwiftUI
import Combine
import Charts
/*struct CryptoDashboardView: View {
    @StateObject private var binanceService = BinanceService()
    @StateObject private var webSocketService = BinanceWebSocketService()
    @State private var selectedCrypto = "BTC"
    @State private var searchQuery = ""
    @State private var walletBalance: Double = 10000  // User's balance in USDT
    @State private var cryptoHoldings: [String: Double] = [:]
    @State private var tradeAmount: String = ""
    @State private var prices: [KlineData] = [] // Use KlineData for richer data
    @State private var selectedTimeframe = "1D" // Match CryptoChartView's timeframe
    @State private var showCandlestick = false // Toggle for chart style
    @State private var errorMessage: String? = nil
    
    private let timeframes = ["LIVE", "1D", "1W", "1M", "3M", "1Y"]
    private let cryptoOptions = [
        "BTC", "ETH", "XRP", "ADA", "SOL", "BNB", "DOGE", "SHIB",
        "LTC", "MATIC", "AVAX", "LINK", "ALGO", "XLM", "TRX", "VET"
    ]

    var body: some View {
        NavigationStack {
            ScrollView { // Ensure scrollability for the entire dashboard
                VStack(spacing: 20) {
                    // 🔍 Search Bar for Crypto
                    TextField("Search Crypto (e.g., BTC, ETH)", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue in
                            if !newValue.isEmpty {
                                if let crypto = cryptoOptions.first(where: { $0.lowercased().contains(newValue.lowercased()) }) {
                                    selectedCrypto = crypto
                                    updateCryptoData()
                                }
                            }
                        }

                    // 🔴 Live Price Display
                    Text("🔴 Live Price: \(selectedCrypto) $\(String(format: "%.2f", webSocketService.livePrice))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    // Crypto Picker for Common Cryptos (Updated to match CryptoChartView)
                    Picker("Select Crypto", selection: $selectedCrypto) {
                        ForEach(cryptoOptions, id: \.self) { symbol in
                            Text(symbol).tag(symbol)
                        }
                    }
                    .pickerStyle(.menu) // Use menu for a cleaner look, matching CryptoChartView
                    .onChange(of: selectedCrypto) { _ in updateCryptoData() }

                    // Wallet Balance & Holdings
                    VStack {
                        Text("💰 Wallet Balance: $\(String(format: "%.2f", walletBalance)) USDT")
                            .font(.headline)
                        Text("📦 Holdings: \(cryptoHoldings[selectedCrypto] ?? 0) \(selectedCrypto)")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Buy Crypto Section
                    HStack {
                        TextField("Amount", text: $tradeAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Button("Buy") {
                            buyCrypto()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()

                    // Chart Controls (Toggle for chart style)
                    HStack {
                        Toggle(isOn: $showCandlestick) {
                            Text("Candlestick Mode")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                    }
                    .padding(.horizontal)

                    // 🔹 Integrate CryptoChartView with Dynamic Data
                    CryptoChartView(
                        selectedCrypto: $selectedCrypto,
                        prices: $prices,
                        selectedTimeframe: $selectedTimeframe,
                        showCandlestick: $showCandlestick,
                        isLoading: $isLoading
                    )
                    .frame(height: 320)
                    .padding(.horizontal)

                    // 🔹 Timeframe Picker (from CryptoChartView)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(timeframes, id: \.self) { timeframe in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedTimeframe = timeframe
                                        fetchHistoricalData(timeframe: timeframe)
                                    }
                                }) {
                                    Text(timeframe)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(
                                            selectedTimeframe == timeframe
                                                ? Color.cyan.opacity(0.9)
                                                : Color.gray.opacity(0.3)
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                        .shadow(color: selectedTimeframe == timeframe ? .cyan : .clear, radius: 4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.black, .purple.opacity(0.4), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(
                    Image(systemName: "hexagon.fill")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.05)
                        .foregroundColor(.purple)
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Crypto Dashboard")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .onAppear {
                updateCryptoData()
                webSocketService.connect(to: selectedCrypto)
            }
            .onDisappear {
                webSocketService.disconnect()
            }
            .alert("System Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Retry", action: { updateCryptoData() })
                Button("Dismiss", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown glitch")
            }
        }
    }

    // 🔄 Fetch Crypto Data
    private func updateCryptoData() {
        binanceService.fetchCryptoPrice(for: selectedCrypto)
        fetchHistoricalData(timeframe: selectedTimeframe)
        webSocketService.connect(to: selectedCrypto)
    }

    // 📉 Fetch Historical Prices (Updated to use KlineData)
    private func fetchHistoricalData(timeframe: String) {
        isLoading = true
        errorMessage = nil
        
        let interval: String
        let limit: Int
        switch timeframe {
        case "LIVE": (interval, limit) = ("1m", 60)
        case "1D": (interval, limit) = ("1h", 24)
        case "1W": (interval, limit) = ("4h", 42)
        case "1M": (interval, limit) = ("1d", 30)
        case "3M": (interval, limit) = ("1d", 90)
        case "1Y": (interval, limit) = ("1w", 52)
        default: (interval, limit) = ("1d", 30)
        }
        
        let urlString = "https://api.binance.us/api/v3/klines?symbol=\(selectedCrypto)USDT&interval=\(interval)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid data stream"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Connection failed: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Server offline"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                    errorMessage = "Data corruption detected"
                    return
                }
                
                let newPrices = json.compactMap { kline -> KlineData? in
                    guard let open = Double(kline[1] as? String ?? "0"),
                          let high = Double(kline[2] as? String ?? "0"),
                          let low = Double(kline[3] as? String ?? "0"),
                          let close = Double(kline[4] as? String ?? "0"),
                          let volume = Double(kline[5] as? String ?? "0") else { return nil }
                    return KlineData(open: open, high: high, low: low, close: close, volume: volume)
                }
                prices = newPrices
            }
        }.resume()
    }

    // ✅ Buy Crypto Logic
    private func buyCrypto() {
        print("🟢 Buy button tapped!")

        guard let price = binanceService.cryptoPrices[selectedCrypto],
              let amount = Double(tradeAmount),
              amount > 0 else {
            print("❌ Invalid input: Price = \(binanceService.cryptoPrices[selectedCrypto] ?? 0), Amount = \(tradeAmount)")
            return
        }

        let cost = price * amount
        print("💰 Cost: \(cost), Wallet Balance: \(walletBalance)")

        if cost <= walletBalance {
            walletBalance -= cost
            cryptoHoldings[selectedCrypto, default: 0] += amount
            print("✅ Purchase successful! New Wallet Balance: \(walletBalance), Holdings: \(cryptoHoldings[selectedCrypto] ?? 0)")
        } else {
            print("❌ Insufficient funds! Needed: \(cost), Available: \(walletBalance)")
        }
    }

    // ✅ Sell Crypto
    private func sellCrypto() {
        guard let price = binanceService.cryptoPrices[selectedCrypto],
              let amount = Double(tradeAmount), amount > 0 else { return }
        if let holdings = cryptoHoldings[selectedCrypto], holdings >= amount {
            walletBalance += price * amount
            cryptoHoldings[selectedCrypto]! -= amount
        }
    }
    
    // ✅ Generic function to fetch JSON data from API
    func fetchData<T: Decodable>(urlString: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 1, userInfo: nil)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}*/








import SwiftUI
import Combine

struct CryptoDashboardView: View {
    @StateObject private var binanceService = BinanceService()
    @StateObject private var webSocketService = BinanceWebSocketService()
    @State private var selectedCrypto = "BTC"
    @State private var searchQuery = ""
    @State private var walletBalance: Double = 10000  // User's balance in USDT
    @State private var cryptoHoldings: [String: Double] = [:]
    @State private var tradeAmount: String = ""
    @State private var prices: [KlineData] = []
    @State private var historicalPrices: [Double] = []
    @State private var showCryptoChartView = false
    @State private var selectedTimeframe: String 
    @Binding var isLoading: Bool
    

                var body: some View {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Text("Welcome to Crypto Dashboard")
                                .font(.title)
                                .fontWeight(.bold)

                            // ✅ "Invest in Crypto" Button
                            Button(action: {
                                showCryptoChartView = true // Activate navigation
                            }) {
                                Text("Invest in Crypto")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.cyan)
                                    .cornerRadius(10)
                                    .shadow(color: .cyan, radius: 4)
                            }
                            .padding(.horizontal)

                            // ✅ NavigationLink to CryptoChartView
                            NavigationStack {
                                VStack {
                                    Button("View Crypto Chart") {
                                        showCryptoChartView = true
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .navigationDestination(isPresented: $showCryptoChartView) {
                                    CryptoChartView(selectedCrypto: $selectedCrypto, prices: $prices, selectedTimeframe: $selectedTimeFrame, isLoading: $isLoading, showCandlestick: $showCandleStick)
                                }
                            }
                        }
                        .padding()
                        .background(LinearGradient(colors: [.black, .purple.opacity(0.4), .black], startPoint: .top, endPoint: .bottom))
                        .ignoresSafeArea()
                    
                
            
            // 🔍 Search Bar for Crypto
            TextField("Search Crypto (e.g. BTC, ETH)", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchQuery) { newValue in
                    if !newValue.isEmpty {
                        selectedCrypto = newValue.uppercased()
                        updateCryptoData()
                    }
                }

            Text("🔴 Live Price: \(selectedCrypto) $\(String(format: "%.2f", webSocketService.livePrice))")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)

            // Crypto Picker for Common Cryptos
            Picker("Select Crypto", selection: $selectedCrypto) {
                ForEach(["BTC", "ETH", "BNB", "DOGE", "XRP"], id: \.self) { symbol in
                    Text(symbol).tag(symbol)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedCrypto) { _ in updateCryptoData() }

            // Price Display
            if let price = binanceService.cryptoPrices[selectedCrypto] {
                Text("$\(String(format: "%.2f", price))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else {
                ProgressView()
            }

            // Wallet Balance & Holdings
            VStack {
                Text("💰 Wallet Balance: $\(String(format: "%.2f", walletBalance)) USDT")
                    .font(.headline)
                Text("📦 Holdings: \(cryptoHoldings[selectedCrypto] ?? 0) \(selectedCrypto)")
                    .font(.headline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // Buy Crypto Section
            HStack {
                TextField("Amount", text: $tradeAmount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                Button("Buy") {
                    buyCrypto()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()

            // Historical Price Chart
            if historicalPrices.isEmpty {
                ProgressView("Loading Historical Prices...")
            } else {
                CryptoChartView(selectedCrypto: $selectedCrypto)
                    .frame(height: 250)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            updateCryptoData()
        }
        .onDisappear {
            webSocketService.disconnect()
        }
    }

    // 🔄 Fetch Crypto Data
    private func updateCryptoData() {
        binanceService.fetchCryptoPrice(for: selectedCrypto)
        fetchHistoricalPrices(for: selectedCrypto)
    }

    // 📉 Fetch Historical Prices
    private func fetchHistoricalPrices(for symbol: String, interval: String = "1d", limit: Int = 30) {
        let urlString = "https://api.binance.us/api/v3/klines?symbol=\(symbol)USDT&interval=\(interval)&limit=\(limit)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] {
                let prices = json.compactMap { Double(($0[4] as? String) ?? "0") }
                DispatchQueue.main.async {
                    self.historicalPrices = prices
                }
            }
        }.resume()
    }

    // ✅ Buy Crypto Logic
    private func buyCrypto() {
        print("🟢 Buy button tapped!")

        guard let price = binanceService.cryptoPrices[selectedCrypto],
              let amount = Double(tradeAmount),
              amount > 0 else {
            print("❌ Invalid input: Price = \(binanceService.cryptoPrices[selectedCrypto] ?? 0), Amount = \(tradeAmount)")
            return
        }

        let cost = price * amount
        print("💰 Cost: \(cost), Wallet Balance: \(walletBalance)")

        if cost <= walletBalance {
            walletBalance -= cost
            cryptoHoldings[selectedCrypto, default: 0] += amount
            print("✅ Purchase successful! New Wallet Balance: \(walletBalance), Holdings: \(cryptoHoldings[selectedCrypto] ?? 0)")
        } else {
            print("❌ Insufficient funds! Needed: \(cost), Available: \(walletBalance)")
        }
    }

    
    // ✅ Sell Crypto
    private func sellCrypto() {
        guard let price = binanceService.cryptoPrices[selectedCrypto], let amount = Double(tradeAmount), amount > 0 else { return }
        if let holdings = cryptoHoldings[selectedCrypto], holdings >= amount {
            walletBalance += price * amount
            cryptoHoldings[selectedCrypto]! -= amount
        }
    }
    
    // ✅ Generic function to fetch JSON data from API
    func fetchData<T: Decodable>(urlString: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 1, userInfo: nil)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
