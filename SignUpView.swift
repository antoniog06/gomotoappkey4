//
//  SignUpView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/7/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var statusMessage: String = ""
    @Binding var isLoggedIn: Bool

    // Driver-specific fields
    @State private var licenseNumber: String = ""
    @State private var drivingExperience: String = ""
    @State private var languagesSpoken: String = ""
    @State private var emergencyContact: String = ""
    @State private var dateOfBirth: String = ""
    @State private var address: String = ""

    // Vehicle Information for Drivers
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: String = ""
    @State private var licensePlate: String = ""
    @State private var color: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .bold()

                TextField("Full Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Phone Number", text: $phone)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                Text("Sign Up As")
                    .font(.title2)

                HStack {
                    Button(action: { selectedRole = "user" }) {
                        Text("User")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedRole == "user" ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { selectedRole = "driver" }) {
                        Text("Driver")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedRole == "driver" ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Driver-specific Information
                if selectedRole == "driver" {
                    Group {
                        TextField("License Number", text: $licenseNumber)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Driving Experience (e.g. 5 years)", text: $drivingExperience)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Languages Spoken", text: $languagesSpoken)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Emergency Contact", text: $emergencyContact)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Date of Birth (MM/DD/YYYY)", text: $dateOfBirth)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Address", text: $address)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }

                    Divider().padding(.vertical)

                    Text("Vehicle Information")
                        .font(.title3)
                        .bold()

                    TextField("Make", text: $make)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    TextField("Model", text: $model)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    TextField("Year", text: $year)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    TextField("License Plate", text: $licensePlate)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    TextField("Color", text: $color)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }

                Button(action: signUp) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }

    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !selectedRole.isEmpty, !name.isEmpty, !phone.isEmpty else {
            statusMessage = "Please fill in all fields and select a role."
            return
        }

        guard password == confirmPassword else {
            statusMessage = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                statusMessage = "Error: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user else { return }
            let db = Firestore.firestore()
            let collection = selectedRole == "driver" ? "drivers" : "users"

            var userData: [String: Any] = [
                "userId": user.uid,
                "email": email,
                "name": name,
                "phone": phone,
                "userType": selectedRole,
                "createdAt": Timestamp()
            ]

            if selectedRole == "driver" {
                userData["licenseNumber"] = licenseNumber
                userData["drivingExperience"] = drivingExperience
                userData["languagesSpoken"] = languagesSpoken
                userData["emergencyContact"] = emergencyContact
                userData["dateOfBirth"] = dateOfBirth
                userData["address"] = address
            }

            db.collection(collection).document(user.uid).setData(userData) { error in
                if let error = error {
                    statusMessage = "Error saving user info: \(error.localizedDescription)"
                } else {
                    if selectedRole == "driver" {
                        let vehicleData: [String: Any] = [
                            "licensePlate": licensePlate,
                            "make": make,  // Ensure the field is named 'make'
                            "model": model,  // Ensure the field is named 'model'
                            "year": year,
                            "color": color  // Ensure the field is named 'color'
                        ]
                        
                        db.collection("drivers").document(user.uid).collection("vehicles").document("vehicleInfo").setData(vehicleData)
                    }
                  /*  if selectedRole == "driver" {
                        let vehicleData: [String: Any] = [
                            "make": make,
                            "model": model,
                            "year": year,
                            "licensePlate": licensePlate,
                            "color": color
                        ]

                        db.collection("drivers").document(user.uid).collection("vehicles").document("vehicleInfo").setData(vehicleData)
                    }*/

                    statusMessage = "Account created successfully!"
                    authManager.login(email: email, password: password) { result in
                        switch result {
                        case .success:
                            isLoggedIn = true
                            authManager.checkUserStatus()
                        case .failure(let error):
                            statusMessage = "Login failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
}

/*
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var statusMessage: String = ""
    @Binding var isLoggedIn: Bool

    // Driver-specific fields
    @State private var licenseNumber: String = ""
    @State private var drivingExperience: String = ""
    @State private var languagesSpoken: String = ""
    @State private var emergencyContact: String = ""
    @State private var dateOfBirth: String = ""
    @State private var address: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .bold()

                TextField("Full Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Phone Number", text: $phone)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                Text("Sign Up As")
                    .font(.title2)

                HStack {
                    Button(action: {
                        selectedRole = "user"
                    }) {
                        Text("User")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedRole == "user" ? Color.green : Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        selectedRole = "driver"
                    }) {
                        Text("Driver")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedRole == "driver" ? Color.green : Color.red.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Show additional fields if Driver is selected
                if selectedRole == "driver" {
                    Group {
                        TextField("License Number", text: $licenseNumber)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Driving Experience (e.g. 5 years)", text: $drivingExperience)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Languages Spoken", text: $languagesSpoken)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Emergency Contact", text: $emergencyContact)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Date of Birth (MM/DD/YYYY)", text: $dateOfBirth)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                        TextField("Address", text: $address)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                Button(action: signUp) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }

    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !selectedRole.isEmpty, !name.isEmpty, !phone.isEmpty else {
            statusMessage = "Please fill in all fields and select a role."
            return
        }

        guard password == confirmPassword else {
            statusMessage = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                statusMessage = "Error: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user else { return }
            let db = Firestore.firestore()
            let collection = selectedRole == "driver" ? "drivers" : "users"

            var userData: [String: Any] = [
                "userId": user.uid,
                "email": email,
                "name": name,
                "phone": phone,
                "userType": selectedRole,
                "createdAt": Timestamp()
            ]

            if selectedRole == "driver" {
                userData["licenseNumber"] = licenseNumber
                userData["drivingExperience"] = drivingExperience
                userData["languagesSpoken"] = languagesSpoken
                userData["emergencyContact"] = emergencyContact
                userData["dateOfBirth"] = dateOfBirth
                userData["address"] = address
            }

            db.collection(collection).document(user.uid).setData(userData) { error in
                if let error = error {
                    statusMessage = "Error saving user info: \(error.localizedDescription)"
                } else {
                    statusMessage = "Account created successfully!"
                    
                    // Automatically log in the user after sign up
                    authManager.login(email: email, password: password) { result in
                        switch result {
                        case .success:
                            isLoggedIn = true
                            authManager.checkUserStatus()
                        case .failure(let error):
                            statusMessage = "Login failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
}*/

/*import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: String = ""
    @State private var name: String = "" // Collect user's name
    @State private var phone: String = "" // Collect user's phone
    @State private var statusMessage: String = ""
    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()

            TextField("Full Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            TextField("Phone Number", text: $phone)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Text("Sign Up As")
                .font(.title2)

            HStack {
                Button(action: {
                    selectedRole = "user"
                }) {
                    Text("User")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedRole == "user" ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    selectedRole = "driver"
                }) {
                    Text("Driver")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedRole == "driver" ? Color.green : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            Button(action: signUp) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !selectedRole.isEmpty, !name.isEmpty, !phone.isEmpty else {
            statusMessage = "Please fill in all fields and select a role."
            return
        }

        guard password == confirmPassword else {
            statusMessage = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                statusMessage = "Error: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user else { return }
            let db = Firestore.firestore()
            let collection = selectedRole == "driver" ? "drivers" : "users" // ✅ Select correct collection

            db.collection(collection).document(user.uid).setData([
                "userId": user.uid,
                "email": email,
                "name": name,
                "phone": phone,
                "userType": selectedRole, // ✅ Ensures userType is stored correctly
                "createdAt": Timestamp()
            ]) { error in
                if let error = error {
                    statusMessage = "Error saving user info: \(error.localizedDescription)"
                } else {
                    statusMessage = "Account created successfully!"
                    
                    // ✅ Automatically log in the user after sign up
                    authManager.login(email: email, password: password) { result in
                        switch result {
                        case .success:
                            isLoggedIn = true
                            authManager.checkUserStatus() // ✅ Ensures correct dashboard is shown
                        case .failure(let error):
                            statusMessage = "Login failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }

    private func redirectToMainView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: MainView())
            window.makeKeyAndVisible()
        }
    }
    
   
}*/


/*   private func signUp() {
       guard !email.isEmpty, !password.isEmpty, !selectedRole.isEmpty, !name.isEmpty, !phone.isEmpty else {
           statusMessage = "Please fill in all fields and select a role."
           return
       }

       guard password == confirmPassword else {
           statusMessage = "Passwords do not match."
           return
       }

       Auth.auth().createUser(withEmail: email, password: password) { result, error in
           if let error = error {
               statusMessage = "Error: \(error.localizedDescription)"
               return
           }

           guard let user = result?.user else { return }
           let db = Firestore.firestore()
           db.collection("users").document(user.uid).setData([
               "userId": user.uid,
               "email": email,
               "name": name,
               "phone": phone,
               "userType": selectedRole
           ]) { error in
               if let error = error {
                   statusMessage = "Error saving user info: \(error.localizedDescription)"
               } else {
                   statusMessage = "Account created successfully!"
                   // Automatically log in the user after sign up
                   authManager.login(email: email, password: password) { result in
                       switch result {
                       case .success:
                           isLoggedIn = true
                       case .failure(let error):
                           statusMessage = "Login failed: \(error.localizedDescription)"
                       }
                   }
               }
           }
       }
   }*/
