//
//  CyberpunkChart.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/25/25.
//


/*import SwiftUI
import Charts
import Combine


struct CyberpunkChart: View {
    @State private var prices: [KlineData] = []
    @State private var isLoading = false
    @State private var showCandlestick = true

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Scanning Network...")
                    .progressViewStyle(.circular)
                    .tint(Color.cyan)
                    .font(.system(size: 14, design: .monospaced))
            } else if prices.isEmpty {
                Text("No signal detected")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(Color.gray)
            } else {
                chartView
            }
        }
        .frame(height: 300)
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.purple.opacity(0.5), radius: 10)
    }

    // 🔹 Chart View
    private var chartView: some View {
        Chart {
            if showCandlestick {
                candlestickMarks
            } else {
                lineAndAreaMarks
            }
        }
    }

    // 🔹 Candlestick Chart Marks
    private var candlestickMarks: some ChartContent {
        ForEach(prices, id: \.time) { kline in
            BarMark(
                x: .value("Time", kline.time),
                yStart: .value("Low", kline.low),
                yEnd: .value("High", kline.high),
                width: .fixed(2)
            )
            .foregroundStyle(Color.gray.opacity(0.5)) // Wick
            
            BarMark(
                x: .value("Time", kline.time),
                yStart: .value("Open", kline.open),
                yEnd: .value("Close", kline.close),
                width: .fixed(8)
            )
            .foregroundStyle(kline.close >= kline.open ? Color.cyan : Color.red) // Body
        }
    }

    // 🔹 Line and Area Chart Marks (✅ Fixed AreaMark)
    private var lineAndAreaMarks: some ChartContent {
        ForEach(prices, id: \.time) { kline in
            LineMark(
                x: .value("Time", kline.time),
                y: .value("Price", kline.close)
            )
            .foregroundStyle(
                Gradient(colors: [Color.cyan, Color.purple, Color.cyan]) // Neon gradient
            )
            .interpolationMethod(.catmullRom)
            .symbol {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 6)
                    .shadow(color: Color.cyan, radius: 2)
            }
        }
        
        AreaMark(
            x: .value("Time", prices.map { $0.time }), // ✅ FIXED: Use mapped values
            yStart: .value("Price", prices.map { $0.close }.min() ?? 0), // ✅ Lowest price
            yEnd: .value("Price", prices.map { $0.close }) // ✅ Use actual closing prices
        )
        .foregroundStyle(Color.cyan.opacity(0.1))
    }
}

#Preview {
    CyberpunkChart()
}*/
