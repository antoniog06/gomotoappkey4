
import FirebaseStorage
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @State private var profileImageURL: String?
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var dateOfBirth: String = ""
    @State private var address: String = ""
    @State private var emergencyContact: String = ""
    @State private var driversLicenseNumber: String = ""
    @State private var drivingExperience: String = ""
    @State private var languagesSpoken: String = ""
    @State private var vehicleDetails: String = ""
    @State private var role: String = ""  // Track if user is a driver or user

    @State private var isEditingProfile: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage?
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                profileImageSection
                userInfoSection
                actionButtons
                Spacer()
            }
            .padding()
        }
        .onAppear { fetchProfile() }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(
                isEditing: $isEditingProfile,
                name: $name,
                phone: $phone,
                dateOfBirth: $dateOfBirth,
                address: $address,
                emergencyContact: $emergencyContact,
                driversLicenseNumber: $driversLicenseNumber,
                drivingExperience: $drivingExperience,
                languagesSpoken: $languagesSpoken,
                vehicleDetails: $vehicleDetails
               
            )
        }
        .sheet(isPresented: $showImagePicker, content: {
            ImagePicker(image: $selectedImage, onImagePicked: uploadProfileImage)
        })
    }
}

// MARK: - Profile Sections
extension ProfileView {
    private var profileImageSection: some View {
        ZStack {
            if let imageUrl = profileImageURL, !imageUrl.isEmpty {
                WebImage(url: URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }

            Button(action: { showImagePicker.toggle() }) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.blue))
                    .frame(width: 30, height: 30)
                    .offset(x: 40, y: 40)
            }
        }
        .padding(.top)
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileDetailRow(icon: "person.fill", title: "Name", value: name)
            ProfileDetailRow(icon: "envelope.fill", title: "Email", value: email)
            ProfileDetailRow(icon: "phone.fill", title: "Phone", value: phone)
            ProfileDetailRow(icon: "calendar", title: "Date of Birth", value: dateOfBirth)
            ProfileDetailRow(icon: "house.fill", title: "Address", value: address)
            ProfileDetailRow(icon: "phone.arrow.up.right.fill", title: "Emergency Contact", value: emergencyContact)
            
            // Show driver-specific info only if the role is driver
            if role == "driver" {
                ProfileDetailRow(icon: "idcard.fill", title: "License Number", value: driversLicenseNumber)
                ProfileDetailRow(icon: "car.fill", title: "Driving Experience", value: drivingExperience)
                ProfileDetailRow(icon: "globe", title: "Languages Spoken", value: languagesSpoken)
              //  ProfileDetailRow(icon: "car.2.fill", title: "Vehicle Details", value: vehicleDetails)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)))
        .shadow(radius: 5)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { isEditingProfile.toggle() }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.8))
                .foregroundColor(.black)
                .cornerRadius(10)
            }

            Button(action: logout) {
                HStack {
                    Image(systemName: "arrow.left.circle.fill")
                    Text("Logout")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Profile Data Handling
extension ProfileView {
    private func fetchProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Determine role by checking drivers collection first
        db.collection("drivers").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.role = "driver"
                populateProfileData(from: data)
            } else {
                // If not a driver, fetch from users collection
                db.collection("users").document(userId).getDocument { snapshot, _ in
                    if let data = snapshot?.data() {
                        self.role = "user"
                        populateProfileData(from: data)
                    }
                }
            }
        }
    }

    private func populateProfileData(from data: [String: Any]) {
        self.name = data["name"] as? String ?? "Unknown"
        self.email = data["email"] as? String ?? "Unknown"
        self.phone = data["phone"] as? String ?? "Unknown"
        self.dateOfBirth = data["dateOfBirth"] as? String ?? "Not Provided"
        self.address = data["address"] as? String ?? "Not Provided"
        self.emergencyContact = data["emergencyContact"] as? String ?? "Not Provided"
        
        if role == "driver" {
            self.driversLicenseNumber = data["driversLicenseNumber"] as? String ?? "Not Provided"
            self.drivingExperience = data["drivingExperience"] as? String ?? "Not Provided"
            self.languagesSpoken = data["languagesSpoken"] as? String ?? "Not Provided"
         //   self.vehicleDetails = data["vehicleDetails"] as? String ?? "Not Provided"
        }
        
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, _ in
                    if let url = url {
                        let collection = role == "driver" ? "drivers" : "users"
                        db.collection(collection).document(userId).updateData(["profileImageURL": url.absoluteString])
                        self.profileImageURL = url.absoluteString
                    }
                }
            }
        }
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Profile Detail Row
struct ProfileDetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text("\(title):")
                .bold()
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}



/*import FirebaseStorage
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @State private var profileImageURL: String?
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var dateOfBirth: String = ""
    @State private var address: String = ""
    @State private var emergencyContact: String = ""
    @State private var driversLicenseNumber: String = ""
    @State private var drivingExperience: String = ""
    @State private var languagesSpoken: String = ""
    @State private var vehicleDetails: String = ""
    
    @State private var isEditingProfile: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage?
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                profileImageSection
                userInfoSection
                actionButtons
                Spacer()
            }
            .padding()
        }
        .onAppear { fetchProfile() }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(
                isEditing: $isEditingProfile,
                name: $name,
                phone: $phone,
                dateOfBirth: $dateOfBirth,
                address: $address,
                emergencyContact: $emergencyContact,
                driversLicenseNumber: $driversLicenseNumber,
                drivingExperience: $drivingExperience,
                languagesSpoken: $languagesSpoken,
                vehicleDetails: $vehicleDetails
            )
        }
        .sheet(isPresented: $showImagePicker, content: {
            ImagePicker(image: $selectedImage, onImagePicked: uploadProfileImage)
        })
    }
}

// MARK: - Profile Sections
extension ProfileView {
    private var profileImageSection: some View {
        ZStack {
            if let imageUrl = profileImageURL, !imageUrl.isEmpty {
                WebImage(url: URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }

            Button(action: { showImagePicker.toggle() }) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.blue))
                    .frame(width: 30, height: 30)
                    .offset(x: 40, y: 40)
            }
        }
        .padding(.top)
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileDetailRow(icon: "person.fill", title: "Name", value: name)
            ProfileDetailRow(icon: "envelope.fill", title: "Email", value: email)
            ProfileDetailRow(icon: "phone.fill", title: "Phone", value: phone)
            ProfileDetailRow(icon: "calendar", title: "Date of Birth", value: dateOfBirth)
            ProfileDetailRow(icon: "house.fill", title: "Address", value: address)
            ProfileDetailRow(icon: "phone.arrow.up.right.fill", title: "Emergency Contact", value: emergencyContact)
            ProfileDetailRow(icon: "idcard.fill", title: "License Number", value: driversLicenseNumber)
            ProfileDetailRow(icon: "car.fill", title: "Driving Experience", value: drivingExperience)
            ProfileDetailRow(icon: "globe", title: "Languages Spoken", value: languagesSpoken)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)))
        .shadow(radius: 5)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { isEditingProfile.toggle() }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.8))
                .foregroundColor(.black)
                .cornerRadius(10)
            }

            Button(action: logout) {
                HStack {
                    Image(systemName: "arrow.left.circle.fill")
                    Text("Logout")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Profile Data Handling
extension ProfileView {
    private func fetchProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.name = data["name"] as? String ?? "Unknown"
                self.email = data["email"] as? String ?? "Unknown"
                self.phone = data["phone"] as? String ?? "Unknown"
                self.dateOfBirth = data["dateOfBirth"] as? String ?? "Not Provided"
                self.address = data["address"] as? String ?? "Not Provided"
                self.emergencyContact = data["emergencyContact"] as? String ?? "Not Provided"
                self.driversLicenseNumber = data["driversLicenseNumber"] as? String ?? "Not Provided"
                self.drivingExperience = data["drivingExperience"] as? String ?? "Not Provided"
                self.languagesSpoken = data["languagesSpoken"] as? String ?? "Not Provided"
                self.profileImageURL = data["profileImageURL"] as? String ?? ""
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, _ in
                    if let url = url {
                        db.collection("users").document(userId).updateData(["profileImageURL": url.absoluteString])
                        self.profileImageURL = url.absoluteString
                    }
                }
            }
        }
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Profile Detail Row
struct ProfileDetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text("\(title):")
                .bold()
                .foregroundColor(.white) // Make the title bold and white for better contrast
            Spacer()
            Text(value)
                .foregroundColor(.white) // Change value color to white for better readability
                .fontWeight(.semibold)   // Make it slightly bolder
        }
        .padding(.vertical, 4) // Add some vertical padding for spacing
    }
}*/

