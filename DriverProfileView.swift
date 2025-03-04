//
//  DriverProfileView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - 🔹 Driver Vehicle Info Component
struct DriverProfileView: View {
    @Binding var licensePlate: String
    @Binding var model: String
    @Binding var make: String
    @Binding var year: String
    @Binding var color: String
    private let db = Firestore.firestore()
    let imageUrl: String?
    @Binding var isOffline: Bool
    @State private var profileImageURL: String? = nil
    var body: some View {
        VStack {
            VStack {
                
                if let url = imageUrl, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
            }
                
            
            Text("Vehicle Information")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("Vehicle Make", text: $make)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("License Plate", text: $licensePlate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("year", text: $year)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Vehicle Model", text: $model)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Vehicle Color", text: $color)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: saveVehicleInfo) {
                Text("Saved Vehicle Info")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    private func saveVehicleInfo() {
        guard let currentUser = Auth.auth().currentUser else { return }
        db.collection("users").document(currentUser.uid).updateData([
            "vehicleInfo": [
                "vehicleMake": make,
                "licensePlate": licensePlate,
                "year": year,
                "vehicleModel": model,
                "vehicleColor": color
            ]
        ]) { error in
            if let error = error {
                print("Error saving vehicle info: \(error.localizedDescription)")
            } else {
                print("Vehicle info saved successfully!")
            }
        }
    }
}

