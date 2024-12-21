import SwiftUI

struct ProfileView: View {
    @State private var name: String = "John Doe"
    @State private var email: String = "johndoe@example.com"

    var body: some View {
        VStack(spacing: 20) {
            Text("My Profile")
                .font(.title)
                .fontWeight(.bold)

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                saveProfile()
            }) {
                Text("Save Changes")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    private func saveProfile() {
        // Simulate saving profile details
        print("Profile saved: \(name), \(email)")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}