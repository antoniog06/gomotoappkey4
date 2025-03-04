//
//  PricingEngine.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import Foundation

class PricingEngine {
    
    // 🚖 Ride Fare Calculation
    
        
        static func calculateRideFare(distanceInMiles: Double, durationInMinutes: Double) -> (totalFare: Double, adminFee: Double, driverEarnings: Double) {
            let baseFare = 2.50
            let costPerMile = 1.75
            let costPerMinute = 0.35

            let rideFare = baseFare + (costPerMile * distanceInMiles) + (costPerMinute * durationInMinutes)

            let adminFee = rideFare > 50 ? max(2, rideFare * 0.06) : 2
            let driverEarnings = rideFare - adminFee

            return (totalFare: rideFare, adminFee: adminFee, driverEarnings: driverEarnings)
        }
    
    
    // 🍔 Food Delivery Fee Calculation
   
        
        // 🍔 Dynamic Food Delivery Fee Calculation (Same as Uber Eats)
   
        
        static func calculateDeliveryFee(orderAmount: Double, distanceInMiles: Double) -> (totalFee: Double, adminFee: Double, driverEarnings: Double) {
            let baseDeliveryFee: Double
            
            switch distanceInMiles {
                case 0...2: baseDeliveryFee = 3.49
                case 2...5: baseDeliveryFee = 4.99
                case 5...10: baseDeliveryFee = 7.99
                default: baseDeliveryFee = 9.99
            }
            
            let adminFee = 1.50
            let driverEarnings = baseDeliveryFee - adminFee

            return (totalFee: baseDeliveryFee, adminFee: adminFee, driverEarnings: driverEarnings)
        }
    }
    









// extra funcions
/*    static func calculateDeliveryFee(orderAmount: Double, distanceInMiles: Double) -> (totalFee: Double, adminFee: Double, driverEarnings: Double) {
        let deliveryBaseFee = 3.99
        let deliveryFee = deliveryBaseFee + (0.50 * distanceInMiles) // $0.50 per mile

        // Admin Fee Calculation
        let adminFee = orderAmount > 50 ? max(2, orderAmount * 0.05) : 2
        let driverEarnings = deliveryFee - adminFee

        return (totalFee: deliveryFee, adminFee: adminFee, driverEarnings: driverEarnings)
    } */
/*  static func calculateRideFare(distanceInMiles: Double, durationInMinutes: Double) -> (totalFare: Double, adminFee: Double, driverEarnings: Double) {
      let baseFare = 1.50
      let costPerMile = 1.50
      let costPerMinute = 0.25

      // Calculate total ride fare
      let rideFare = baseFare + (costPerMile * distanceInMiles) + (costPerMinute * durationInMinutes)

      // Admin Fee Calculation (Hybrid Model)
      let adminFee = rideFare > 50 ? max(2, rideFare * 0.05) : 2
      let driverEarnings = rideFare - adminFee

      return (totalFare: rideFare, adminFee: adminFee, driverEarnings: driverEarnings)
  }*/
