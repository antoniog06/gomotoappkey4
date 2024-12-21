import Foundation

struct Item: Identifiable {
    var id: UUID = UUID() // Automatically generates a unique ID
    var name: String // The name of the item
    var timestamp: Date = Date() // The date and time when the item is created

    init(name: String) {
        self.name = name
    }
}

