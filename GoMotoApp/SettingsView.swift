import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    @State private var name: String = "John Doe"
    @State private var email: String = Auth.auth().currentUser?.email ?? "johndoe@example.com"
    @State private var phoneNumber: String = "123-456-7890"

    var body: some View {
        VStack {
            Form {
                // Section for Personal Information
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                // Section for Theme Selection
                Section(header: Text("App Theme")) {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        Text("Default").tag(Theme.defaultTheme)
                        Text("Blue").tag(Theme.blueTheme)
                        Text("Green").tag(Theme.greenTheme)
                        Text("Purple").tag(Theme.purpleTheme)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }

            // Save Changes Button
            Button(action: saveChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.selectedTheme.backgroundColor)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Settings")
        .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
    }

    private func saveChanges() {
        themeManager.saveTheme() // Save theme to UserDefaults
        print("Changes Saved: Name: \(name), Email: \(email), Phone: \(phoneNumber)")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager())
    }
}

/*import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    @State private var name: String = "John Doe"
    @State private var email: String = Auth.auth().currentUser?.email ?? "johndoe@example.com"
    @State private var phoneNumber: String = "123-456-7890"

    var body: some View {
        VStack {
            Form {
                // Section for Personal Information
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                // Section for Theme Selection
                Section(header: Text("App Theme")) {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        Text("Default").tag(Theme.defaultTheme)
                        Text("Blue").tag(Theme.blueTheme)
                        Text("Green").tag(Theme.greenTheme)
                        Text("Purple").tag(Theme.purpleTheme)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }

            // Save Changes Button
            Button(action: saveChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.selectedTheme.backgroundColor)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Settings")
        .background(themeManager.selectedTheme.backgroundColor.ignoresSafeArea())
    }

    private func saveChanges() {
        themeManager.saveTheme() // Save theme to UserDefaults
        print("Changes Saved: Name: \(name), Email: \(email), Phone: \(phoneNumber)")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager())
    }
}
*/
