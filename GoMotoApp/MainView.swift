//
//  MainView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var userType: String = ""
    @State private var loading: Bool = true
    @State private var isLoggedIn: Bool = false
    @State private var selectedMode: RideFoodMode = .ride
    @State private var userOrders: [FoodOrder] = []
    
    @EnvironmentObject var authManager: AuthManager // AuthManager injected globally

    var body: some View {
        Group {
            if loading {
                loadingView
            } else if !isLoggedIn {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager) // Inject auth manager
            } else {
                mainDashboardView // 🚀 Dynamic dashboard view based on userType & mode
            }
        }
        .onAppear(perform: checkAuthStatus)
    }
}

// MARK: - 🏠 Dynamic Dashboard View
extension MainView {
    private var mainDashboardView: some View {
        NavigationView {
            VStack {
                // **🌟 Picker for Ride or Food Mode**
                Picker(selection: $selectedMode, label: Text("Select Mode")) {
                    Text("🚖 Ride").tag(RideFoodMode.ride)
                    Text("🍔 Food").tag(RideFoodMode.food)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // **🌟 Show View Based on Role**
                if userType == "driver" {
                    if selectedMode == .ride {
                        DriverDashboardView(isLoggedIn: $isLoggedIn)
                    } else {
                        FoodDriverDashboardView(isLoggedIn: $isLoggedIn)
                    }
                } else if userType == "user" {
                    if selectedMode == .ride {
                        UserDashboardView(isLoggedIn: $isLoggedIn)
                    } else {
                        FoodUserDashboardView(isLoggedIn: $isLoggedIn, userOrders: $userOrders)
                    }
                } else {
                    roleNotFoundView
                }
            }
            .navigationTitle("GoMoto Super App")
        }
        .environmentObject(authManager)
    }
}

// MARK: - 🔐 Authentication & Firestore Handling
extension MainView {
    private func checkAuthStatus() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No user is currently logged in.")
            updateAuthState(isLogged: false, role: nil)
            return
        }
        fetchUserType(for: user.uid)
    }

    private func fetchUserType(for userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching user type: \(error.localizedDescription)")
                updateAuthState(isLogged: false, role: nil)
                return
            }
            guard let data = snapshot?.data(), let fetchedUserType = data["userType"] as? String else {
                print("⚠️ User type not found for \(userId).")
                updateAuthState(isLogged: false, role: nil)
                return
            }
            updateAuthState(isLogged: true, role: fetchedUserType)
        }
    }

    private func updateAuthState(isLogged: Bool, role: String?) {
        DispatchQueue.main.async {
            self.isLoggedIn = isLogged
            self.userType = role ?? ""
            self.loading = false
        }
    }
}

// MARK: - ⏳ Loading & Error Views
extension MainView {
    private var loadingView: some View {
        VStack {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
            Text("Please wait...")
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
    }

    private var roleNotFoundView: some View {
        VStack {
            Text("❌ Error: Role not found")
                .foregroundColor(.red)
                .font(.headline)
            Button(action: { isLoggedIn = false }) {
                Text("🔄 Back to Login")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - 🚀 Enum for Ride & Food Modes
enum RideFoodMode {
    case ride
    case food
}

// main view with logic bellow
/*
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var userType: String = ""
    @State private var loading: Bool = true
    @State private var isLoggedIn: Bool = false
    @State private var selectedMode: RideFoodMode = .ride
    
    @EnvironmentObject var authManager: AuthManager // AuthManager provided globally

    var body: some View {
        Group {
            if loading {
                loadingView
            } else if !isLoggedIn {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager) // Pass to WelcomeView
            } else {
                switch userType {
                case "driver":
                    DriverDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                case "user":
                    UserDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                default:
                    roleNotFoundView
                }
            }
        }
        .onAppear(perform: checkAuthStatus)
    }
}

// MARK: - Subviews
extension MainView {
    private var loadingView: some View {
        VStack {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
            Text("Please wait...")
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
    }

    private var roleNotFoundView: some View {
        VStack {
            Text("Error: Role not found")
                .foregroundColor(.red)
                .font(.headline)
            Button(action: { isLoggedIn = false }) {
                Text("Back to Login")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Authentication & Firestore
extension MainView {
    private func checkAuthStatus() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            updateAuthState(isLogged: false, role: nil)
            return
        }
        fetchUserType(for: user.uid)
    }

    private func fetchUserType(for userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), let fetchedUserType = data["userType"] as? String else {
                print("User type not found in Firestore for user \(userId). \(error?.localizedDescription ?? "")")
                updateAuthState(isLogged: false, role: nil)
                return
            }
            updateAuthState(isLogged: true, role: fetchedUserType)
        }
    }

    private func updateAuthState(isLogged: Bool, role: String?) {
        DispatchQueue.main.async {
            self.isLoggedIn = isLogged
            self.userType = role ?? ""
            self.loading = false
        }
    }
}*/


/*import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var userType: String = ""
    @State private var loading: Bool = true
    @State private var isLoggedIn: Bool = false
    @State private var selectedMode: RideFoodMode = .ride
    
    @EnvironmentObject var authManager: AuthManager
    private let orderService = OrderService() // Instance of OrderService

    var body: some View {
        Group {
            if loading {
                loadingView
            } else if !isLoggedIn {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager)
            } else {
                contentView
            }
        }
        .onAppear(perform: checkAuthStatus)
    }
}

// MARK: - Dynamic Content Based on Role
extension MainView {
    private var contentView: some View {
        NavigationView {
            VStack {
                Picker(selection: $selectedMode, label: Text("Select Mode")) {
                    Text("🚖 Ride").tag(RideFoodMode.ride)
                    Text("🍔 Food").tag(RideFoodMode.food)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedMode == .ride {
                    if userType == "driver" {
                        DriverDashboardView(isLoggedIn: $isLoggedIn)
                    } else {
                        UserDashboardView(isLoggedIn: $isLoggedIn)
                    }
                } else {
                    if userType == "driver" {
                        FoodDriverDashboardView(isLoggedIn: $isLoggedIn)
                    } else {
                        FoodUserDashboardView(isLoggedIn: $isLoggedIn)
                    }
                }
            }
            .navigationTitle("GoMoto Super App")
        }
        .environmentObject(authManager)
    }
}

// MARK: - Authentication & Firestore Handling
extension MainView {
    private func checkAuthStatus() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            updateAuthState(isLogged: false, role: nil)
            return
        }
        fetchUserType(for: user.uid)
    }

    private func fetchUserType(for userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), let fetchedUserType = data["userType"] as? String else {
                print("User type not found in Firestore for user \(userId). \(error?.localizedDescription ?? "")")
                updateAuthState(isLogged: false, role: nil)
                return
            }
            updateAuthState(isLogged: true, role: fetchedUserType)
        }
    }

    private func updateAuthState(isLogged: Bool, role: String?) {
        DispatchQueue.main.async {
            self.isLoggedIn = isLogged
            self.userType = role ?? ""
            self.loading = false
        }
    }
}

// MARK: - Subviews
extension MainView {
    private var loadingView: some View {
        VStack {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
            Text("Please wait...")
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
    }
}

// MARK: - Enum for Ride & Food Modes
enum RideFoodMode {
    case ride
    case food
}*/
