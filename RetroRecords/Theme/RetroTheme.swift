//
//  RetroTheme.swift
//  RetroRecords
//
//  1970s warm record store aesthetic - orange, brown, mustard vibes
//

import SwiftUI

struct RetroTheme {
    // MARK: - 1970s Warm Color Palette

    // Light Mode Colors
    static let warmCream = Color(hex: "#FAF3E0")
    static let burntOrange = Color(hex: "#CC5500")
    static let mustard = Color(hex: "#D4A017")
    static let chocolate = Color(hex: "#5C4033")
    static let avocado = Color(hex: "#568203")
    static let rust = Color(hex: "#B7410E")
    static let cork = Color(hex: "#C4A777")
    static let vinyl = Color(hex: "#1A1A1A")
    static let caramel = Color(hex: "#8B5A2B")
    static let parchment = Color(hex: "#F5DEB3")

    // Dark Mode Colors
    static let darkWood = Color(hex: "#2C1810")
    static let darkBrown = Color(hex: "#1A0F0A")
    static let amber = Color(hex: "#FFBF00")
    static let warmWhite = Color(hex: "#FFF8DC")
    static let darkCork = Color(hex: "#4A3728")

    // MARK: - Adaptive Colors

    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkWood : warmCream
    }

    static func adaptiveCardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkCork : parchment
    }

    static func adaptiveTextPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warmWhite : chocolate
    }

    static func adaptiveTextSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#C4A777") : caramel
    }

    static func adaptiveAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? amber : burntOrange
    }

    static func adaptiveBackgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                gradient: Gradient(colors: [darkBrown, darkWood]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [warmCream, parchment]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Shadows

    static func cardShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : caramel.opacity(0.3)
    }

    // MARK: - Status Colors

    static let success = avocado
    static let warning = mustard
    static let error = rust
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
