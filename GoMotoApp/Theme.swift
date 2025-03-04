//
//  Theme.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/7/25.
//
import SwiftUI

// MARK: - Theme Struct
struct Theme: Hashable, Codable {
    var primaryColor: Color
    var secondaryColor: Color
    var accentColor: Color
    var textColor: Color
    var backgroundColor: Color

    // Predefined Themes
    static let defaultTheme = Theme(
        primaryColor: .blue,
        secondaryColor: .gray,
        accentColor: .red,
        textColor: .white,
        backgroundColor: .black
    )
    static let blueTheme = Theme(
        primaryColor: .blue,
        secondaryColor: .gray,
        accentColor: .red,
        textColor: .white,
        backgroundColor: .blue
    )
    static let greenTheme = Theme(
        primaryColor: .green,
        secondaryColor: .gray,
        accentColor: .red,
        textColor: .white,
        backgroundColor: .green
    )
    static let purpleTheme = Theme(
        primaryColor: .purple,
        secondaryColor: .gray,
        accentColor: .red,
        textColor: .white,
        backgroundColor: .purple
    )

    // Helper function for encoding and decoding Colors
    enum CodingKeys: String, CodingKey {
        case primaryColor, secondaryColor, accentColor, textColor, backgroundColor
    }

    init(primaryColor: Color, secondaryColor: Color, accentColor: Color, textColor: Color, backgroundColor: Color) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.primaryColor = Color(hex: try container.decode(String.self, forKey: .primaryColor))
        self.secondaryColor = Color(hex: try container.decode(String.self, forKey: .secondaryColor))
        self.accentColor = Color(hex: try container.decode(String.self, forKey: .accentColor))
        self.textColor = Color(hex: try container.decode(String.self, forKey: .textColor))
        self.backgroundColor = Color(hex: try container.decode(String.self, forKey: .backgroundColor))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primaryColor.toHex(), forKey: .primaryColor)
        try container.encode(secondaryColor.toHex(), forKey: .secondaryColor)
        try container.encode(accentColor.toHex(), forKey: .accentColor)
        try container.encode(textColor.toHex(), forKey: .textColor)
        try container.encode(backgroundColor.toHex(), forKey: .backgroundColor)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var hexValue: UInt64 = 0
        scanner.scanHexInt64(&hexValue)
        let red = Double((hexValue >> 16) & 0xFF) / 255
        let green = Double((hexValue >> 8) & 0xFF) / 255
        let blue = Double(hexValue & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
