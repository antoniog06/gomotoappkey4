
import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import Stripe
import StripePaymentSheet

@main
struct GoMotoApp: App {
    init() {
        StripeAPI.defaultPublishableKey = "sk_test_51Iq9ruJe5shBun0GpRJAy7HTi61CPrprbmSoMdgaZiGyw2m2bQN10FSUWwHRsByrCcNGkm8NBvRryE79cJKF4rNG0017XImhCg"
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authManager = AuthManager()
    @StateObject var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager.shared
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                switch authManager.userType {
                case "driver":
                    DriverDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .environmentObject(themeManager)
                        .onAppear {
                            UIApplication.shared.registerForRemoteNotifications()
                            locationManager.startUpdatingLocation { result in
                                switch result {
                                case .success(let location):
                                    print("Location updated: \(location)")
                                case .failure(let error):
                                    print("Failed to update location: \(error.localizedDescription)")
                                }
                            }
                        }

                case "user":
                    MainTabView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .environmentObject(themeManager)
                        .onAppear {
                            UIApplication.shared.registerForRemoteNotifications()
                            locationManager.startUpdatingLocation { result in
                                switch result {
                                case .success(let location):
                                    print("Location updated: \(location)")
                                case .failure(let error):
                                    print("Failed to update location: \(error.localizedDescription)")
                                }
                            }
                        }

                default:
                    ProgressView()
                        .onAppear {
                            authManager.checkUserStatus()
                        }
                }
            } else {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .onAppear {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
            }
        }
    }
}

// original ride view bellow
/*import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import Stripe
import StripePaymentSheet

@main
struct GoMotoApp: App {
    init() {
        StripeAPI.defaultPublishableKey = "sk_test_51Iq9ruJe5shBun0GpRJAy7HTi61CPrprbmSoMdgaZiGyw2m2bQN10FSUWwHRsByrCcNGkm8NBvRryE79cJKF4rNG0017XImhCg"
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authManager = AuthManager()
    @StateObject var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager.shared // ✅ FIXED
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                switch authManager.userType {
                    case "driver":
                    
                    DriverDashboardView (isLoggedIn: $isLoggedIn)
                            .environmentObject(authManager)
                            .environmentObject(locationManager)
                            .environmentObject(themeManager)
                            .onAppear {
                                UIApplication.shared.registerForRemoteNotifications()
                                locationManager.startUpdatingLocation { result in
                                    switch result {
                                    case .success(let location):
                                        print("Location updated: \(location)")
                                    case .failure(let error):
                                        print("Failed to update location: \(error.localizedDescription)")
                                    }
                                }
                            }

                    case "user":
                        UserDashboardView(isLoggedIn: $isLoggedIn)
                            .environmentObject(authManager)
                            .environmentObject(locationManager)
                            .environmentObject(themeManager)
                            .onAppear {
                                UIApplication.shared.registerForRemoteNotifications()
                                locationManager.startUpdatingLocation { result in
                                    switch result {
                                    case .success(let location):
                                        print("Location updated: \(location)")
                                    case .failure(let error):
                                        print("Failed to update location: \(error.localizedDescription)")
                                    }
                                }
                            }

                    default:
                    ProgressView()
                        .onAppear {
                            authManager.checkUserStatus()
                            // .environmentObject(authManager)
                         //   .environmentObject(themeManager)
                        }
                }
            } else {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .onAppear {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
            }
        }
    }
}*/
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import AVKit
import GoogleMaps
import GooglePlaces

class AppDelegate: UIResponder, NSObject, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        // Set Firebase Messaging Delegate
        Messaging.messaging().delegate = self
        
        // Request push notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Push notifications permission granted.")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ Push notifications permission denied.")
            }
        }
        
        return true
    }
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .allButUpsideDown // Supports all orientations except upside-down
    }
    
 

  

        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
            GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
            GMSPlacesClient.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
            
            return true
        }
    
    
    // ✅ Register device for remote notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("📲 APNS Token Received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        // Set APNS token in Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // ❌ Failed to register for remote notifications
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for APNS: \(error.localizedDescription)")
    }
}

// MARK: - 🔹 Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
    
    // ✅ Get FCM Token after APNS token is registered
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🚀 Firebase FCM Token: \(fcmToken ?? "None")")
        
        // ✅ Save the FCM token to Firestore
        guard let uid = Auth.auth().currentUser?.uid, let token = fcmToken else { return }
        let db = Firestore.firestore()
        db.collection("drivers").document(uid).updateData(["fcmToken": token]) { error in
            if let error = error {
                print("❌ Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("✅ FCM token saved successfully.")
            }
        }
    }
}

// MARK: - 🔹 Handle Push Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // ✅ Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📩 Received push notification while in foreground: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge]) // Show notification in foreground
    }
    
    // ✅ Handle notification tap to open the app
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📩 User tapped notification: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}


/*import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth

@main
struct GoMotoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authManager = AuthManager()
    @StateObject var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager.shared // ✅ FIXED
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                if authManager.userType == "driver" {
                    DriverDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .onAppear {
                            locationManager.startUpdatingLocation { result in
                                switch result {
                                case .success(let location):
                                    print("Location updated: \(location)")
                                case .failure(let error):
                                    print("Failed to update location: \(error.localizedDescription)")
                                }
                            }
                        }
                } else if authManager.userType == "user" {
                    UserDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .onAppear {
                            locationManager.startUpdatingLocation { result in
                                switch result {
                                case .success(let location):
                                    print("Location updated: \(location)")
                                case .failure(let error):
                                    print("Failed to update location: \(error.localizedDescription)")
                                }
                            }
                        }
                } else {
                    VStack {
                        Text("Error: Unknown user type")
                            .foregroundColor(.red)
                            .font(.headline)
                        Button(action: {
                            authManager.logout { result in
                                switch result {
                                case .success:
                                    isLoggedIn = false
                                    print("Logged out successfully.")
                                case .failure(let error):
                                    print("Error during logout: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            Text("Back to Login")
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager)
            }
        }
    }
}*/


/*import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth

@main
struct GoMotoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authManager = AuthManager()
    @StateObject var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager.shared
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                if authManager.userType == "driver" {
                    DriverDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .onAppear {
                            locationManager.startUpdatingLocation { result in
                                switch result {
                                case .success(let location):
                                    print("Location updated: \(location)")
                                case .failure(let error):
                                    print("Failed to update location: \(error.localizedDescription)")
                                }
                            }
                        }
                } else if authManager.userType == "user" {
                    UserDashboardView(isLoggedIn: $isLoggedIn)
                        .environmentObject(authManager)
                        .environmentObject(locationManager)
                        .onAppear {
                            locationManager.startUpdatingLocation { result in
                                switch result {
                                case .success(let location):
                                    print("Location updated: \(location)")
                                case .failure(let error):
                                    print("Failed to update location: \(error.localizedDescription)")
                                }
                            }
                        }
                } else {
                    VStack {
                        Text("Error: Unknown user type")
                            .foregroundColor(.red)
                            .font(.headline)
                        Button(action: {
                            authManager.logout { result in
                                switch result {
                                case .success:
                                    isLoggedIn = false
                                    print("Logged out successfully.")
                                case .failure(let error):
                                    print("Error during logout: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            Text("Back to Login")
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environmentObject(authManager)
            }
        }
    }
}*/
/*import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // logic for csv file bellow
      
                if let filePath = Bundle.main.path(forResource: "default", ofType: "csv") {
                    do {
                        let fileContents = try String(contentsOfFile: filePath)
                        print(fileContents) // Process the data here
                    } catch {
                        print("Error reading file: \(error.localizedDescription)")
                    }
                } else {
                    print("File not found.")
                }
        
            
        
        
        
        // logic for csv file above
        FirebaseApp.configure()
        return true
    }
}*/
// Define a shared data manager class to mimic data handling
class SharedDataManager: ObservableObject {
    @Published var items: [CustomItem] = [] // Use CustomItem instead of Item

    init() {
        loadInitialData()
    }

    func loadInitialData() {
        // Load or initialize your data here
        self.items = [CustomItem(id: UUID(), name: "Sample Item", date: Date())]
    }

    func addItem(_ item: CustomItem) {
        items.append(item)
    }
}

// Define your custom Item model
struct CustomItem: Identifiable {
    var id: UUID
    var name: String
    var date: Date
}


