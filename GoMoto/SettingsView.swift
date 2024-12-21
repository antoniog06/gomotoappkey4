import SwiftUI

struct SettingsView: View {
    @State private var name: String = "John Doe"
    @State private var email: String = "johndoe@example.com"
    @State private var phoneNumber: String = "123-456-7890"
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
            }
            Button(action: saveChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .navigationTitle("Settings")
    }
    
    private func saveChanges() {
        // Add logic to save changes (e.g., persist to a database or API)
        print("Changes Saved: \(name), \(email), \(phoneNumber)")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
