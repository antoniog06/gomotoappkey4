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







