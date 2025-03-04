//
//  LoginView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/7/25.
//


import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isLoggedIn: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Login to GoMotoApp")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: login) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    private func login() {
        authManager.login(email: email, password: password) { result in
            switch result {
            case .success:
                print("Login successful")
                isLoggedIn = true
            case .failure(let error):
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }
}

