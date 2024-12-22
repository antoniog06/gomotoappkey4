import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager = ThemeManager()
    
    @State private var name: String = "John Doe"
    @State private var email: String = "johndoe@example.com"
    @State private var phoneNumber: String = "123-456-7890"

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("App Theme")) {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        Text("Default").tag(Theme.defaultTheme)
                        Text("Blue").tag(Theme.blueTheme)
                        Text("Green").tag(Theme.greenTheme)
                        Text("Purple").tag(Theme.purpleTheme)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            Button(action: saveChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.selectedTheme.backgroundColor)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .navigationTitle("Settings")
        .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
    }

    private func saveChanges() {
        // Add logic to save changes (e.g., persist to a database or API)
        print("Changes Saved: \(name), \(email), \(phoneNumber)")
    }
}

