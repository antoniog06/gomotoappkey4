//
//  CryptoChartView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//

import SwiftUI
import Charts

struct CryptoChartView: View {
    @StateObject private var binanceService = BinanceService()
    
    @Binding var selectedCrypto: String
    @Binding var prices: [KlineData]
    @State private var predictedPrices: [KlineData] = [] // Future projections
    @Binding var selectedTimeframe: String
    @Binding var isLoading: Bool
    @State private var errorMessage: String?
  //  @State private var prices: [KlineData] = []
 //   @State private var selectedTimeframe: String = "1D"
    @Binding var showCandlestick: Bool
 //   @State private var isLoading: Bool = false
    private let timeframes = ["LIVE", "1D", "1W", "1M", "3M", "1Y"]

    var body: some View {
        VStack(spacing: 10) {
            // ✅ Price Header
            headerView
            
            // ✅ Chart View
            chartView
                .frame(height: calculateChartHeight())
                .padding(.horizontal)
            
            // ✅ Timeframe Buttons
            timeframePicker
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(selectedCrypto)
        .foregroundColor(.white)
        .onAppear {
            fetchHistoricalData(timeframe: selectedTimeframe)
        }
    }
    
    // 🔹 Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(selectedCrypto) Price Chart")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                
                Text("$\(prices.last?.close ?? 0, specifier: "%.6f")")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("\(priceChange())")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(priceChange().contains("-") ? .red : .green)
            }
            Spacer()
            
            // ⭐ Favorite & Share Buttons
            HStack {
                Button(action: { print("Favorited!") }) {
                    Image(systemName: "star")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                Button(action: { print("Shared!") }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
        }
        .padding(.horizontal)
    }

    // 🔹 Timeframe Picker
    private var timeframePicker: some View {
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

    // ✅ Dynamic Chart Height Calculation
    private func calculateChartHeight() -> CGFloat {
        let range = (prices.map { $0.high }.max() ?? 1) - (prices.map { $0.low }.min() ?? 0)
        return max(150, min(350, range * 5000)) // Auto-adjust height dynamically
    }

    // ✅ Chart View
    private var chartView: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading Data...")
                    .progressViewStyle(.circular)
                    .tint(.cyan)
            } else if prices.isEmpty {
                Text("No Data Available")
                    .foregroundColor(.gray)
            } else {
                Chart {
                    // 🔵 Historical Prices (Solid Black)
                    ForEach(prices) { kline in
                        LineMark(
                            x: .value("Time", kline.time),
                            y: .value("Price", kline.close)
                        )
                        .foregroundStyle(.black)
                        .interpolationMethod(.catmullRom)
                    }

                    // 🔘 Predicted Prices (Dotted Gray)
                    ForEach(predictedPrices) { kline in
                        LineMark(
                            x: .value("Time", kline.time),
                            y: .value("Price", kline.close)
                        )
                        .foregroundStyle(.gray.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                    }

                    // 📍 Vertical Dashed Line for Current Time
                    RuleMark(x: .value("Time", getCurrentTime()))
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .annotation(alignment: .trailing) {
                            Text(getCurrentTimeLabel())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 12, design: .monospaced))
                    }
                }
                .background(Color.black.opacity(0.9))
                .cornerRadius(16)
            }
        }
    }

    // ✅ Fetch Data
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
        
        print("🔍 Fetching data from: \(urlString)") // Debugging URL

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    errorMessage = "Network Error: \(error.localizedDescription)"
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                    print("❌ Failed to parse JSON")
                    errorMessage = "Failed to parse data"
                    return
                }

                let newPrices = json.map { kline -> KlineData in
                    return KlineData(
                        time: kline[0] as? Int64 ?? 0,
                        open: Double(kline[1] as? String ?? "0") ?? 0,
                        high: Double(kline[2] as? String ?? "0") ?? 0,
                        low: Double(kline[3] as? String ?? "0") ?? 0,
                        close: Double(kline[4] as? String ?? "0") ?? 0,
                        volume: Double(kline[5] as? String ?? "0") ?? 0
                    )
                }
                print("✅ Data fetched successfully: \(newPrices.count) entries")
                prices = newPrices
            }
        }.resume()
    }

    // ✅ Helper Functions
    private func getCurrentTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func getCurrentTimeLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private func priceChange() -> String {
        guard prices.count > 1 else { return "+0.00%" }
        let first = prices.first?.close ?? 0
        let last = prices.last?.close ?? 0
        let change = ((last - first) / first) * 100
        return String(format: "%+.2f%%", change)
    }
}
                    
/*import SwiftUI
import Charts

struct CryptoChartView: View {
    @StateObject private var binanceService = BinanceService()
    @State private var selectedCrypto = "DOGE"
    @State private var searchQuery = ""
    @State private var prices: [KlineData] = []
    @State private var selectedTimeframe = "1D"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCandlestick = false
    @State private var walletBalance: Double = 10000
    @State private var cryptoHoldings: [String: Double] = [:]
    @State private var tradeAmount: String = ""
    
    private let timeframes = ["LIVE", "1D", "1W", "1M", "3M", "1Y"]
    private let cryptoOptions = ["BTC", "ETH", "XRP", "ADA", "SOL", "DOT", "DOGE", "SHIB", "BNB"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 🔍 Search Bar
                    TextField("Search Crypto (e.g. BTC, ETH)", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchQuery) { newValue in
                            let validSymbols = ["BTC", "ETH", "XRP", "ADA", "SOL", "DOT", "DOGE", "SHIB", "BNB"]
                            
                            if !newValue.isEmpty {
                                let uppercasedSymbol = newValue.uppercased()
                                if validSymbols.contains(uppercasedSymbol) {
                                    selectedCrypto = uppercasedSymbol
                                    fetchHistoricalData(timeframe: selectedTimeframe)
                                }
                            } else {
                                selectedCrypto = "DOGE" // Reset to a default coin
                                fetchHistoricalData(timeframe: selectedTimeframe)
                            }
                        }
                    
                    
                    // 🔹 Crypto Picker (Dropdown)
                    cryptoPicker
                    
                    // 🔹 Price Display
                    priceDisplay
                    
                    // 🔹 Candlestick Toggle
                    Toggle("Candlestick Mode", isOn: $showCandlestick)
                        .padding(.horizontal)
                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                    
                    // 🔹 Chart View
                    chartView
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    // 🔹 Timeframe Buttons
                    timeframePicker
                    
                    // 🔹 Wallet Balance & Holdings
                    walletBalanceView
                    
                    // 🔹 Buy/Sell Crypto Section
                    tradeControls
                }
                .padding()
            }
            .background(
                LinearGradient(colors: [.black, .purple.opacity(0.4), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Crypto Tracker")
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
                fetchHistoricalData(timeframe: selectedTimeframe)
                
                // 🔄 Auto Refresh Every 5 Seconds for Live Price
                Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                    binanceService.fetchCryptoPrice(for: selectedCrypto)
                }
            }
            // ✅ Hide Keyboard on Tap Outside
            .gesture(
                
                TapGesture().onEnded { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            )
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    // 🔹 Crypto Picker
    private var cryptoPicker: some View {
        HStack {
            
            Menu {
                ForEach(cryptoOptions, id: \.self) { crypto in
                    Button(crypto) {
                        selectedCrypto = crypto
                        fetchHistoricalData(timeframe: selectedTimeframe)
                    }
                }
            } label: {
                HStack {
                    Text(selectedCrypto)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.down")
                }
                .foregroundColor(.cyan)
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cyan.opacity(0.7), lineWidth: 1)
                )
            }
        }
    }
    
    // 🔹 Price Display
    private var priceDisplay: some View {
        VStack {
            Text("$\(prices.last?.close ?? 0, specifier: "%.2f")")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .cyan, radius: 4)
            
            Text("\(priceChange())")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(priceChange().contains("-") ? .red : .cyan)
        }
    }
    
    // 🔹 Chart View
    private var chartView: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading Data...")
                    .progressViewStyle(.circular)
                    .tint(.cyan)
            } else if prices.isEmpty {
                Text("No Data Available")
                    .foregroundColor(.gray)
            } else {
                Chart {
                    if showCandlestick {
                        ForEach(prices) { kline in
                            BarMark(
                                x: .value("Time", kline.time),
                                yStart: .value("Low", kline.low),
                                yEnd: .value("High", kline.high),
                                width: .fixed(2)
                            )
                            .foregroundStyle(.gray.opacity(0.5)) // Wick
                            
                            BarMark(
                                x: .value("Time", kline.time),
                                yStart: .value("Open", kline.open),
                                yEnd: .value("Close", kline.close),
                                width: .fixed(8)
                            )
                            .foregroundStyle(kline.close >= kline.open ? .cyan : .red) // Body
                        }
                    } else {
                        ForEach(prices) { kline in
                            LineMark(
                                x: .value("Time", kline.time),
                                y: .value("Price", kline.close)
                            )
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .background(Color.black.opacity(0.9))
                .cornerRadius(16)
            }
        }
    }
    
    // 🔹 Wallet Balance & Holdings
    private var walletBalanceView: some View {
        VStack {
            Text("💰 Wallet Balance: $\(String(format: "%.2f", walletBalance)) USDT")
                .font(.headline)
            Text("📦 Holdings: \(cryptoHoldings[selectedCrypto] ?? 0) \(selectedCrypto)")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 🔹 Buy/Sell Crypto Section
    private var tradeControls: some View {
        HStack {
            TextField("Amount", text: $tradeAmount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            
            Button("Buy") { buyCrypto() }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            
            Button("Sell") { sellCrypto() }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
    
    // 🔹 Helper Functions
    private func updateSelectedCrypto() {
        let upperQuery = searchQuery.uppercased()
        if cryptoOptions.contains(upperQuery) {
            selectedCrypto = upperQuery
            fetchHistoricalData(timeframe: selectedTimeframe)
        }
    }
    
    
    
    
    // 🔹 Fetch Historical Data from Binance API
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
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                    errorMessage = "Failed to parse data"
                    return
                }
                
                let newPrices = json.map { kline -> KlineData in
                    return KlineData(
                        time: [0] as? Int64 ?? 0,
                        open: Double(kline[1] as? String ?? "0") ?? 0,
                        high: Double(kline[2] as? String ?? "0") ?? 0,
                        low: Double(kline[3] as? String ?? "0") ?? 0,
                        close: Double(kline[4] as? String ?? "0") ?? 0,
                        volume: Double(kline[5] as? String ?? "0") ?? 0
                    )
                }
                prices = newPrices
                
            }
        }.resume()
    }
    
    // 🔹 Calculate Price Change Percentage
    private func priceChange() -> String {
        guard prices.count > 1 else { return "+0.00%" }
        let first = prices.first?.close ?? 0
        let last = prices.last?.close ?? 0
        let change = ((last - first) / first) * 100
        return String(format: "%+.2f%%", change)
    }
    
    // 🔹 Refresh Chart Data
    private func refreshData() {
        fetchHistoricalData(timeframe: selectedTimeframe)
    }
    // 🔹 Timeframe Picker
    private var timeframePicker: some View {
        HStack(spacing: 12) {
            ForEach(timeframes, id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                    fetchHistoricalData(timeframe: timeframe)
                }) {
                    Text(timeframe)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(selectedTimeframe == timeframe ? Color.cyan.opacity(0.9) : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .shadow(color: selectedTimeframe == timeframe ? .cyan : .clear, radius: 4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 40)
    }
    
    // 🔹 Buy Crypto
    private func buyCrypto() {
        guard let price = binanceService.cryptoPrices[selectedCrypto], let amount = Double(tradeAmount), amount > 0 else { return }
        let cost = price * amount
        if cost <= walletBalance {
            walletBalance -= cost
            cryptoHoldings[selectedCrypto, default: 0] += amount
        }
    }
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    // 🔹 Sell Crypto
    private func sellCrypto() {
        guard let price = binanceService.cryptoPrices[selectedCrypto], let amount = Double(tradeAmount), amount > 0 else { return }
        if let holdings = cryptoHoldings[selectedCrypto], holdings >= amount {
            walletBalance += price * amount
            cryptoHoldings[selectedCrypto]! -= amount
        }
    }
    
}*/



   
 
