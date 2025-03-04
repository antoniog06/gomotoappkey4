//
//  VehicleInfoView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/8/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
struct VehicleInfoView: View {
    @Binding var make: String
    @Binding var model: String
    @Binding var year: String
    @Binding var licensePlate: String
    @Binding var color: String
    @Binding var baseRateMultiplier: Double
    @Binding var surgePricing: Double
    @State private var isSurgeEnabled: Bool = false
    @State private var isLoading: Bool = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Vehicle Information")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                vehicleForm
                
                if isLoading {
                    ProgressView("Saving...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                if let success = successMessage {
                    Text(success)
                        .foregroundColor(.green)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
              //  vehicleForm
            }
            .padding()
        }
        .onAppear(perform: fetchVehicleInfo)
    }
}

// MARK: - UI Components
extension VehicleInfoView {
    private var vehicleForm: some View {
        Group {
            Group {
                TextField("Make", text: $make)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Model", text: $model)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Year", text: $year)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                TextField("License Plate", text: $licensePlate)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Color", text: $color)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
            }
            
            Group {
                HStack {
                    Text("Base Rate Multiplier")
                        .foregroundColor(.white)
                    Slider(value: $baseRateMultiplier, in: 0.5...3.0, step: 0.1)
                    Text(String(format: "%.1f", baseRateMultiplier))
                        .foregroundColor(.white)
                }
                
                // Surge Pricing
                Toggle(isOn: $isSurgeEnabled) {
                    Text("Surge Pricing").foregroundColor(.white)
                }
                
                if isSurgeEnabled {
                    HStack {
                        Text("Surge Pricing Multiplier")
                        Slider(value: $surgePricing, in: 1.0...3.0, step: 0.1)
                        Text(String(format: "%.1f", surgePricing))
                    }
                }
                
                // Save Button with Validation
                Button(action: saveVehicleInfo) {
                    Text("Save Vehicle Info")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allFieldsFilled ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!allFieldsFilled) // Disable button when fields are empty
                .padding(.top, 5)
            }
            .padding()
        }
    }
        // Computed Property for Field Validation
        private var allFieldsFilled: Bool {
            !make.isEmpty && !model.isEmpty && !year.isEmpty && !licensePlate.isEmpty && !color.isEmpty
        }
        
      
    }


// MARK: - Firestore Functions
extension VehicleInfoView {
    private func fetchVehicleInfo() {
        guard let driverId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }
        
        isLoading = true
        db.collection("drivers").document(driverId).getDocument { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error fetching vehicle info: \(error.localizedDescription)"
                return
            }
            
            if let data = snapshot?.data() {
                make = data["make"] as? String ?? ""
                model = data["model"] as? String ?? ""
                year = data["year"] as? String ?? ""
                licensePlate = data["licensePlate"] as? String ?? ""
                color = data["color"] as? String ?? ""
                baseRateMultiplier = data["baseRateMultiplier"] as? Double ?? 1.0
                surgePricing = data["surgePricing"] as? Double ?? 1.0
                
            }
        }
    }
    
    private func saveVehicleInfo() {
        // Check if all fields are filled
        guard !make.isEmpty, !model.isEmpty, !year.isEmpty, !licensePlate.isEmpty, !color.isEmpty else {
            errorMessage = "Please fill out all fields before saving."
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }

        let vehicleData: [String: Any] = [
            "make": make,
            "model": model,
            "year": year,
            "licensePlate": licensePlate,
            "color": color,
            "baseRateMultiplier": baseRateMultiplier,
            "isSurgeEnable": isSurgeEnabled,
            "surgePricing": surgePricing  // Only if surge is enabled
        ]

        isLoading = true
        db.collection("drivers").document(userId).collection("vehicles").document("vehicleInfo").setData(vehicleData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to save vehicle info: \(error.localizedDescription)"
            } else {
                errorMessage = "Vehicle information saved successfully!"
            }
        }
    
    }
}


/*import FirebaseAuth
import SwiftUI
import Firebase
import FirebaseFirestore

struct VehicleInfoView: View {
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: String = ""
    @State private var licensePlate: String = ""
    @State private var color: String = ""
    @State private var baseRateMultiplier: Double = 1.0
    @State private var surgePricing: Bool = false
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Vehicle Information")
                .font(.title)
                .bold()
            
            Group {
                TextField("Make", text: $make)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Model", text: $model)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Year", text: $year)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                TextField("License Plate", text: $licensePlate)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Color", text: $color)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Group {
                HStack {
                    Text("Base Rate Multiplier")
                    Slider(value: $baseRateMultiplier, in: 0.5...3.0, step: 0.1)
                    Text(String(format: "%.1f", baseRateMultiplier))
                }
                
                Toggle(isOn: $surgePricing) {
                    Text("Surge Pricing")
                }
            }
            
            Button(action: saveVehicleInfo) {
                Text("Save Vehicle Info")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: fetchVehicleInfo)
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .overlay(isLoading ? ProgressView().scaleEffect(2) : nil)
    }
}

// MARK: - Firestore Functions
extension VehicleInfoView {
    private func fetchVehicleInfo() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }
        
        isLoading = true
        db.collection("vehicles").document(userId).getDocument { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error fetching vehicle info: \(error.localizedDescription)"
                return
            }
            
            if let data = snapshot?.data() {
                make = data["make"] as? String ?? ""
                model = data["model"] as? String ?? ""
                year = data["year"] as? String ?? ""
                licensePlate = data["licensePlate"] as? String ?? ""
                color = data["color"] as? String ?? ""
                baseRateMultiplier = data["baseRateMultiplier"] as? Double ?? 1.0
                surgePricing = data["surgePricing"] as? Bool ?? false
            }
        }
    }
    
    private func saveVehicleInfo() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }
        
        let vehicleData: [String: Any] = [
            "make": make,
            "model": model,
            "year": year,
            "licensePlate": licensePlate,
            "color": color,
            "baseRateMultiplier": baseRateMultiplier,
            "surgePricing": surgePricing
        ]
        
        isLoading = true
        db.collection("vehicles").document(userId).setData(vehicleData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to save vehicle info: \(error.localizedDescription)"
            } else {
                errorMessage = "Vehicle information saved successfully!"
            }
        }
    }
}
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

func saveVehicleInfo(make: String, model: String, year: String, licensePlate: String, color: String, baseRateMultiplier: Double, surgePricing: Bool) {
    guard let driverId = Auth.auth().currentUser?.uid else {
        print("Error: User not authenticated.")
        return
    }

    let vehicleData: [String: Any] = [
        "make": make,
        "model": model,
        "year": year,
        "licensePlate": licensePlate,
        "color": color,
        "baseRateMultiplier": baseRateMultiplier,
        "surgePricing": surgePricing
    ]

    let db = Firestore.firestore()
    db.collection("drivers").document(driverId).setData(vehicleData) { error in
        if let error = error {
            print("Error saving vehicle data: \(error.localizedDescription)")
        } else {
            print("Vehicle information saved successfully!")
        }
    }
}*/
