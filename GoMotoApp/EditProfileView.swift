//
//  EditProfileView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 2/2/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Binding var isEditing: Bool
    @Binding var name: String
    @Binding var phone: String
    @Binding var dateOfBirth: String
    @Binding var address: String
    @Binding var emergencyContact: String
    @Binding var driversLicenseNumber: String
    @Binding var drivingExperience: String
    @Binding var languagesSpoken: String
    @Binding var vehicleDetails: String

    private let db = Firestore.firestore()
    private let userId = Auth.auth().currentUser?.uid

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                    TextField("Date of Birth (MM/DD/YYYY)", text: $dateOfBirth)
                    TextField("Address", text: $address)
                }
                
                Section(header: Text("Emergency Contact")) {
                    TextField("Emergency Contact Name & Number", text: $emergencyContact)
                }
                
                Section(header: Text("Driving Information")) {
                    TextField("Driver's License Number", text: $driversLicenseNumber)
                    TextField("Driving Experience (e.g. 5 years)", text: $drivingExperience)
                    TextField("Languages Spoken (e.g. English, Spanish)", text: $languagesSpoken)
                }
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { isEditing = false },
                trailing: Button("Save Changes") { saveProfileChanges() }
            )
        }
    }

    // MARK: - Save Profile Data to Firestore
    private func saveProfileChanges() {
        guard let userId = userId else { return }
        let updatedData: [String: Any] = [
            "name": name,
            "phone": phone,
            "dateOfBirth": dateOfBirth,
            "address": address,
            "emergencyContact": emergencyContact,
            "driversLicenseNumber": driversLicenseNumber,
            "drivingExperience": drivingExperience,
            "languagesSpoken": languagesSpoken,
            "vehicleDetails": vehicleDetails
        ]
        
        db.collection("users").document(userId).updateData(updatedData) { error in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully!")
                isEditing = false // Close the edit view after successful save
            }
        }
    }
}




/*import FirebaseAuth
import SwiftUI
import Firebase

struct EditProfileView: View {
    @Binding var isEditing: Bool
    @Binding var name: String
    @Binding var phone: String
    @Binding var vehicleDetails: String
    @Binding var dateOfBirth: String
    @Binding var address: String
    @Binding var emergencyContact: String
    @Binding var driversLicenseNumber: String
    @Binding var drivingExperience: String
    @Binding var languagesSpoken: String

      
    
    @State private var updatedName: String = ""
    @State private var updatedPhone: String = ""
    @State private var updatedVehicleDetails: String = ""
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false
    
    
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Name Field
                TextField("Full Name", text: $updatedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Phone Field
                TextField("Phone Number", text: $updatedPhone)
                    .keyboardType(.phonePad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Vehicle Details (Only for drivers)
                if !vehicleDetails.isEmpty {
                    TextField("Vehicle Details (Model, License Plate)", text: $updatedVehicleDetails)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }

                // Save Button
                Button(action: saveChanges) {
                    HStack {
                        if isSaving {
                            ProgressView()
                        }
                        Text("Save Changes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isSaving)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") {
                isEditing = false
            })
            .onAppear {
                updatedName = name
                updatedPhone = phone
                updatedVehicleDetails = vehicleDetails
            }
        }
    }
    
    // MARK: - Save Changes to Firestore
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        var updatedData: [String: Any] = [
            "name": updatedName,
            "phone": updatedPhone
        ]
        
        if !vehicleDetails.isEmpty {
            updatedData["vehicleDetails"] = updatedVehicleDetails
        }
        
        db.collection("users").document(userId).updateData(updatedData) { error in
            isSaving = false
            
            if let error = error {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                // Update the parent view
                name = updatedName
                phone = updatedPhone
                vehicleDetails = updatedVehicleDetails
                isEditing = false
            }
        }
    }
}*/
