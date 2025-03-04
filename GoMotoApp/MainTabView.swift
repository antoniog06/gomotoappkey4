//
//  MainTabView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/20/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore




import SwiftUI

struct MainTabView: View {
    @Binding var isLoggedIn: Bool
    @State private var viewModel = CryptoViewModel()
    
    var body: some View {
        TabView {
            UserDashboardView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            RideView()
                .tabItem {
                    Label("Ride", systemImage: "car")
                }
            
            FoodDeliveryView()
                .tabItem {
                    Label("Food", systemImage: "bag")
                }
            
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "creditcard")
                }
            
            CryptoStockView(viewModel: viewModel )
                .tabItem {
                    Label("Invest", systemImage: "chart.bar")
                }
            
            MoviesView()
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
        }
    }
}
