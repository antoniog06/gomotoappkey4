//
//  BinanceService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.


import Foundation
import Combine
import SwiftUI
import Firebase
import Charts
    
// Placeholder for BinanceService (you'll need to define this fully)
class BinanceService: ObservableObject {
    @Published var cryptoPrices: [String: Double] = [:]
    @Published var symbols: [String] = ["BTC", "ETH", "BNB", "XRP", "DOGE", "SHIB"]
    
    func fetchCryptoPrice(for symbol: String) {
        // Simulate fetching price (replace with actual API call)
        DispatchQueue.main.async {
            self.cryptoPrices[symbol] = Double.random(in: 1000...50000) // Mock price
        }
    }
    func fetchAllCryptoPrices() {
        for symbol in symbols {
            fetchCryptoPrice(for: symbol)
        }
    }
    
    func fetchHistoricalData(for symbol: String, interval: String, limit: Int, completion: @escaping ([KlineData]) -> Void) {
        let urlString = "https://api.binance.us/api/v3/klines?symbol=\(symbol)USDT&interval=\(interval)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching historical data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                print("Failed to parse historical data")
                completion([])
                return
            }
            
            let klineData = json.map { kline -> KlineData in
                return KlineData(
                    time: Int64(kline[0] as? String ?? "0") ?? 0,
                    open: Double(kline[1] as? String ?? "0") ?? 0,
                    high: Double(kline[2] as? String ?? "0") ?? 0,
                    low: Double(kline[3] as? String ?? "0") ?? 0,
                    close: Double(kline[4] as? String ?? "0") ?? 0,
                    volume: Double(kline[5] as? String ?? "0") ?? 0
                )
            }
            
            DispatchQueue.main.async {
                completion(klineData)
            }
        }.resume()
    }

struct BinanceTicker: Codable {
    let symbol: String
    let price: String
}
}

/*import Foundation
import Combine

 class BinanceService: ObservableObject {
     @Published var cryptoPrices: [String: Double] = [:]
     @Published var symbols: [String] = ["BTC", "ETH", "BNB", "XRP", "DOGE"]
     private var cancellables = Set<AnyCancellable>()
     var prices: [KlineData] = []

   // Fetch current price for a specific symbol
    func fetchCryptoPrice(for symbol: String) {
        
        
        let urlString = "https://api.binance.us/api/v3/ticker/price?symbol=\(symbol)USDT"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: BinanceTicker.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Binance API Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] ticker in
                self?.cryptoPrices[symbol] = Double(ticker.price) ?? 0
            })
            .store(in: &cancellables)
    }
    
    


    // Fetch historical OHLCV data (Klines) for a symbol
    func fetchHistoricalData(for symbol: String, interval: String = "1d", limit: Int = 30, completion: @escaping ([KlineData]) -> Void) {
        let urlString = "https://api.binance.us/api/v3/klines?symbol=\(symbol)USDT&interval=\(interval)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Historical Data Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
         
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] {
                let newPrices = json.map { kline -> KlineData in
                    return KlineData(
                        time: Int64(kline[0] as? String ?? "0") ?? 0, // Convert time string to Int64
                        open: Double(kline[1] as? String ?? "0") ?? 0,
                        high: Double(kline[2] as? String ?? "0") ?? 0,
                        low: Double(kline[3] as? String ?? "0") ?? 0,
                        close: Double(kline[4] as? String ?? "0") ?? 0,
                        volume: Double(kline[5] as? String ?? "0") ?? 0
                    )
                }
                self.prices = newPrices
                
                DispatchQueue.main.async {
                    completion(newPrices)
                }
            } else {
                completion([])
            }
        }.resume()
    }

    // Fetch prices for all symbols
    func fetchAllCryptoPrices() {
        for symbol in symbols {
            fetchCryptoPrice(for: symbol)
        }
    }

    // ✅ Binance API Response Model
    struct BinanceTicker: Codable {
        let symbol: String
        let price: String
    }
}


    */






