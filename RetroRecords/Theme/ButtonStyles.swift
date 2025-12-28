//
//  ButtonStyles.swift
//  RetroRecords
//
//  Custom button styles with 1970s retro aesthetic
//

import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(RetroTheme.adaptiveAccent(for: colorScheme))
            .cornerRadius(12)
            .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Vinyl Button Style (Circular)

struct VinylButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(RetroTheme.vinyl)
                    .overlay(
                        Circle()
                            .fill(RetroTheme.adaptiveAccent(for: colorScheme))
                            .frame(width: 20, height: 20)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .rotationEffect(.degrees(configuration.isPressed ? -10 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
