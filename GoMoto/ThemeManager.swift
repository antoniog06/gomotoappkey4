import SwiftUI

// MARK: - ThemeManager
class ThemeManager: ObservableObject {
    @Published var selectedTheme: Theme

    init() {
        self.selectedTheme = ThemeManager.loadTheme() ?? Theme.defaultTheme
    }

    func saveTheme() {
        if let data = try? JSONEncoder().encode(selectedTheme) {
            UserDefaults.standard.set(data, forKey: "SelectedTheme")
        }
    }

    static func loadTheme() -> Theme? {
        if let data = UserDefaults.standard.data(forKey: "SelectedTheme"),
           let theme = try? JSONDecoder().decode(Theme.self, from: data) {
            return theme
        }
        return nil
    }
}

// MARK: - Theme Struct
struct Theme: Codable, Equatable, Hashable {
    var backgroundColor: Color {
        Color(hex: backgroundColorHex)
    }
    var textColor: Color {
        Color(hex: textColorHex)
    }

    private var backgroundColorHex: String
    private var textColorHex: String

    static let defaultTheme = Theme(backgroundColorHex: "#000000", textColorHex: "#FFFFFF")
    static let blueTheme = Theme(backgroundColorHex: "#0000FF", textColorHex: "#FFFFFF")
    static let greenTheme = Theme(backgroundColorHex: "#00FF00", textColorHex: "#FFFFFF")
    static let purpleTheme = Theme(backgroundColorHex: "#800080", textColorHex: "#FFFFFF")
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let red = Double((rgbValue >> 16) & 0xff) / 255
        let green = Double((rgbValue >> 8) & 0xff) / 255
        let blue = Double(rgbValue & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

