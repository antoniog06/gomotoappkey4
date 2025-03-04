//
//  ChartElevationEffect.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//


import SwiftUI

struct ChartElevationEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .shadow(radius: 5)
            )
            .padding()
            .animation(.spring(), value: UUID())
    }
}

extension View {
    func chartElevationEffect() -> some View {
        self.modifier(ChartElevationEffect())
    }
   
}
struct ButtonStackEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.02)
            .shadow(radius: 3)
            .animation(.spring(), value: UUID())
    }
}


import SwiftUI

struct EarningsAnalyticsView: View {
    @Binding var earnings: DriverEarnings.Metrics  // Binding to earnings

    var body: some View {
        VStack(spacing: 10) {
            Text("Earnings Summary")
                .font(.title)
                .bold()
                .padding(.bottom, 5)
            
            VStack(spacing: 8) {
                EarningsRow(label: "Total Earnings", value: earnings.totalEarnings) // Removed `.metrics`
                EarningsRow(label: "Bonuses", value: earnings.bonuses)
                EarningsRow(label: "Total with Bonuses", value: earnings.totalEarnings + earnings.bonuses) // Fixed the calculation
                Text("Completed Rides: \(earnings.completedRides)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .shadow(radius: 5)
        }
        .padding()
    }
}

// Reusable Row Component for cleaner UI
struct EarningsRow: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text("$\(value, specifier: "%.2f")")
                .font(.headline)
                .bold()
                .foregroundColor(.green)
        }
    }
}
struct OnlineStatusIndicator: View {
    let isOnline: Bool
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
    }
}
struct PricingControlPanel: View {
    @Binding var baseRate: Double
    @Binding var surge: Double
    
    var body: some View {
        VStack {
            Text("Base Rate Multiplier: \(baseRate, specifier: "%.2f")")
            Slider(value: $baseRate, in: 1...3, step: 0.1)
            
            Text("Surge Pricing: \(surge, specifier: "%.2f")")
            Slider(value: $surge, in: 1...5, step: 0.1)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
        .shadow(radius: 5)
    }
}
/*struct DriverPerformanceMeter: View {
    let metrics: DriverEarnings.Metrics

    var body: some View {
        VStack {
            HStack {
                Text("Completed Rides: \(metrics.completedRides)")
                Spacer()
                Text("Earnings: $\(metrics.totalEarnings, specifier: "%.2f")")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.2)))
            .shadow(radius: 5)
        }
        .padding()
    }
}*/
struct EarningsGraphView: View {
    let earnings: DriverEarnings.Metrics

    var body: some View {
        VStack {
            Text("Total Earnings: $\(earnings.totalEarnings, specifier: "%.2f")")
                .font(.title)
            Text("Completed Rides: \(earnings.completedRides)")
                .font(.headline)
            Text("Bonuses: $\(earnings.bonuses, specifier: "%.2f")")
                .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
        .shadow(radius: 5)
    }
}
struct ChartMorphEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(radius: 5)
            .scaleEffect(1.02)
    }
}

extension View {
    func chartMorphEffect() -> some View {
        self.modifier(ChartMorphEffect())
    }
}
struct DynamicToggleButton: View {
    @Binding var isOn: Bool
    let onLabel: String
    let offLabel: String
    let onColor: Color
    let offColor: Color

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(isOn ? onLabel : offLabel)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isOn ? onColor : offColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
struct DriverInboxView: View {
    var body: some View {
        Text("Inbox - Coming Soon!")
            .font(.largeTitle)
            .padding()
    }
}
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: configuration.isPressed)
    }
}
import SwiftUI

extension AnyTransition {
    static func skewedSlide(_ edge: Edge) -> AnyTransition {
        AnyTransition.move(edge: edge)
            .combined(with: .opacity)
    }
}
extension Animation {
    static var pulse: Animation {
        Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    }
}
extension Animation {
    static func ripple() -> Animation {
        Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    }
}
extension AnyTransition {
    static var textFade: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.9))
    }
}
extension AnyTransition {
    static func cardInsertion(index: Int) -> AnyTransition {
        .scale(scale: 0.95 + 0.05 * Double(index))
    }
    
    static var cardRemoval: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity)
    }
}




