

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isLoggingOut: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Button(action: logoutUser) {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 30)
            }
            .padding()
            .navigationTitle("GoMoto")
            .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
            .alert("Logging Out", isPresented: $isLoggingOut) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You have successfully logged out.")
            }
        }
    }

    private func logoutUser() {
        authManager.logout { result in
            switch result {
            case .success:
                isLoggingOut = true // Trigger the alert
            case .failure(let error):
                print("Error logging out: \(error.localizedDescription)")
            }
        }
    }
}


