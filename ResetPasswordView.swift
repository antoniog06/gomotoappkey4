//
//  ResetPasswordView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/7/25.
//


import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @Environment(\.presentationMode) var presentationMode  // To dismiss the view after success
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSuccess: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            TextField("Enter your email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(isSuccess ? .green : .red)
                    .padding(.horizontal)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .padding()
            }

            Button(action: resetPassword) {
                Text("Reset Password")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .onTapGesture { hideKeyboard() }  // Dismiss keyboard on tap outside
    }

    private func resetPassword() {
        guard !email.isEmpty else {
            message = "Please enter your email address."
            isSuccess = false
            return
        }

        isLoading = true
        hideKeyboard()

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false

            if let error = error {
                message = error.localizedDescription
                isSuccess = false
            } else {
                message = "Password reset email sent!"
                isSuccess = true

                // Automatically dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/*
import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSuccess: Bool = false

    var body: some View {
        VStack {
            Text("Reset Password")
                .font(.title)
                .padding()

            TextField("Enter your email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(isSuccess ? .green : .red)
                    .padding()
            }

            Button(action: resetPassword) {
                Text("Reset Password")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Spacer()
        }
        .padding()
    }

    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = error.localizedDescription
                isSuccess = false
            } else {
                message = "Password reset email sent!"
                isSuccess = true
            }
        }
    }
}*/
