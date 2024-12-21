import SwiftUI
import FirebaseCore

@main
struct GoMotoApp: App {
    init() {
      
        FirebaseApp.configure()
    }
    // Simulate a shared data container
    var sharedDataManager: SharedDataManager = SharedDataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedDataManager) // Pass the data manager to the environment
        }
    }
}

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


