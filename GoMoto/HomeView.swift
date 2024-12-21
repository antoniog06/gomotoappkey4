//
//  HomeView.swift
//  GoMoto
//
//  Created by AnthonyGarcia on 20/12/2024.
//


import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: RideRequestView()) {
                    Text("Request a Ride")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(destination: PaymentView()) {
                    Text("Payments")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(destination: ProfileView()) {
                    Text("My Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(destination: RideHistoryView()) {
                    Text("Ride History")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(destination: LiveMapView()) {
                    Text("Live Map Tracking")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("GoMoto")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
