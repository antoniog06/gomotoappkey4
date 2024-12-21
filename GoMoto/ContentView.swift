//
//  ContentView.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
//


import SwiftData

import SwiftUI



struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: RideRequestView()) {
                    Text("Request a Ride")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: LiveMapView()) {
                    Text("Live Map")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: PaymentView()) {
                    Text("Payments")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: ProfileView()) {
                    Text("Profile")
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: RideHistoryView()) {
                    Text("Ride History")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("GoMoto")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
