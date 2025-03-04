//
//  BinanceWebSocketService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/23/25.
//

import SwiftUI
import Combine

// ✅ WebSocket Service for Real-Time Binance Updates
class BinanceWebSocketService: ObservableObject {
    @Published var livePrice: Double = 0.0
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var cryptoPrices: [String: Double] = [:]
    @Published var simbols: [String] = ["BTC", "ETH", "DOGE"]
    func connect(to symbol: String) {
        let url = URL(string: "wss://stream.binance.com:9443/ws/\(symbol.lowercased())usdt@trade")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessages()
    }
    
    func disconnect() {
        webSocketTask?.cancel()
        webSocketTask = nil
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(.string(let jsonString)):
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let priceString = json["p"] as? String,
                   let price = Double(priceString) {
                    DispatchQueue.main.async {
                        self?.livePrice = price
                    }
                }
                
            case .failure(let error):
                print("❌ WebSocket Error: \(error.localizedDescription)")
            default:
                break
            }
            
            // ✅ Keep Listening
            self?.receiveMessages()
        }
    }
}

/*import SwiftUI
import Combine

// ✅ WebSocket Service for Real-Time Binance Updates
class BinanceWebSocketService: ObservableObject {
    @Published var livePrice: Double = 0.0
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect(symbol: String) {
        let url = URL(string: "wss://stream.binance.com:9443/ws/\(symbol.lowercased())usdt@trade")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessages()
    }
    
    func disconnect() {
        webSocketTask?.cancel()
        webSocketTask = nil
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(.string(let jsonString)):
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let priceString = json["p"] as? String,
                   let price = Double(priceString) {
                    DispatchQueue.main.async {
                        self?.livePrice = price
                    }
                }
                
            case .failure(let error):
                print("❌ WebSocket Error: \(error.localizedDescription)")
            default:
                break
            }
            
            // ✅ Keep Listening
            self?.receiveMessages()
        }
    }
}

// MARK: - Binance Trade Model
struct BinanceTrade: Codable {
    let price: String
}
*/
