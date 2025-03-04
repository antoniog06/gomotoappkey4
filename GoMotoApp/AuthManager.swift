//
//  AuthManager.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/7/25.
//

import FirebaseAuth
import Combine
import SwiftUI
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userType: String? // Stores the user type (e.g., "driver" or "user")

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // ✅ Automatically check login state at initialization
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = user != nil
                self?.checkUserStatus() // ✅ Ensure correct dashboard redirection
            }
        }
    }

    // MARK: - **Login Function**
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            DispatchQueue.main.async {
                self?.isLoggedIn = true
                self?.checkUserStatus() // ✅ Ensure userType is fetched correctly
                completion(.success(()))
            }
        }
    }

    // MARK: - **Logout Function**
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.userType = nil // ✅ Properly reset userType
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - **Fetch User Type from Firestore**
    func checkUserStatus() {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.userType = nil
            }
            return
        }

        let db = Firestore.firestore()

        // ✅ Check both "drivers" and "users" collections
        db.collection("drivers").document(userId).getDocument { [weak self] driverSnapshot, _ in
            if let data = driverSnapshot?.data(), let role = data["userType"] as? String {
                DispatchQueue.main.async {
                    self?.userType = role // ✅ User is a "driver"
                }
                return
            }

            db.collection("users").document(userId).getDocument { [weak self] userSnapshot, _ in
                if let data = userSnapshot?.data(), let role = data["userType"] as? String {
                    DispatchQueue.main.async {
                        self?.userType = role // ✅ User is a "user"
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.userType = "user" // ✅ Default to "user" if not found
                    }
                }
            }
        }
    }

    // MARK: - **Reset Password**
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - **Update Password**
    func updatePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        user.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - **Delete Account**
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        user.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.userType = nil
                }
                completion(.success(()))
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
/*
import FirebaseAuth
import Combine
import SwiftUI
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userType: String? // Stores the user type (e.g., "driver" or "user")

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Automatically check login state at initialization
        isLoggedIn = Auth.auth().currentUser != nil
        fetchUserType() // Fetch the user type after login
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            // Set login state and fetch user type
            self?.isLoggedIn = true
            self?.fetchUserType()
            completion(.success(()))
        }
    }

    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            userType = "" // Reset the user type on logout
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    private func fetchUserType() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(), let fetchedUserType = data["userType"] as? String {
                DispatchQueue.main.async {
                    self?.userType = fetchedUserType
                }
            } else {
                DispatchQueue.main.async {
                    self?.userType = "user" // Default to "user" if not found
                }
            }
        }
    }

    // Reset Password
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Update Password
    func updatePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        user.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Delete Account
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        user.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.isLoggedIn = false
                self.userType = ""
                completion(.success(()))
            }
        }
    }

    deinit {
        // Remove listener on deinitialization
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
*/



