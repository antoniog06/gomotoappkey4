//
//  StoreAPIService.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//


import Foundation

class StoreAPIService {
    
    static func sendOrderToStore(storeID: String, orderDetails: [String: Any], completion: @escaping (Bool) -> Void) {
        
        let apiURL = URL(string: "https://api.store.com/orders/\(storeID)")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: orderDetails, options: [])
        } catch {
            print("Failed to encode order data")
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending order: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Order successfully sent to store!")
                completion(true)
            } else {
                print("Failed to send order.")
                completion(false)
            }
        }
        
        task.resume()
    }
}