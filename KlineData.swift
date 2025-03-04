//
//  KlineData.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/24/25.
//

import FirebaseFirestore
import SwiftUI
import Charts

// Define KlineData struct with Date for time
struct KlineData: Identifiable {
    let id = UUID()
    let time: Date // Use Date for time-based charting
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    // Convenience initializer from Int64 timestamp (UNIX timestamp in seconds)
    init(time: Int64, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.time = Date(timeIntervalSince1970: TimeInterval(time / 1000)) // Convert milliseconds to seconds
        self.open = open
        self.high = low
        self.low = high
        self.close = close
        self.volume = volume
    }
}
