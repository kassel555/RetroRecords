//
//  SettingsView.swift
//  RetroRecords
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance
                        appearanceSection

                        // Collection stats
                        statsSection

                        // About
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            Toggle(isOn: $isDarkMode) {
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    Text("Dark Mode")
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                }
            }
            .tint(RetroTheme.adaptiveAccent(for: colorScheme))

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                Text("Switch to a warm, wood-toned dark theme")
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collection Stats")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            HStack {
                Image(systemName: "opticaldisc.fill")
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                Text("Total Records")
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                Spacer()
                Text("\(store.totalAlbums)")
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            }

            Divider()

            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                Text("Genres")
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                Spacer()
                Text("\(store.allGenres.count)")
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            }

            if !store.allGenres.isEmpty {
                Divider()

                Text("Top Genres")
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                FlowLayout(spacing: 8) {
                    ForEach(store.allGenres.prefix(6), id: \.self) { genre in
                        Text(genre)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About RetroRecords")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            HStack {
                // Vinyl icon
                ZStack {
                    Circle()
                        .fill(RetroTheme.vinyl)
                        .frame(width: 50, height: 50)

                    Circle()
                        .fill(RetroTheme.adaptiveAccent(for: colorScheme))
                        .frame(width: 18, height: 18)

                    Circle()
                        .fill(RetroTheme.vinyl)
                        .frame(width: 6, height: 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    Text("Vinyl Collection Tracker")
                        .font(.caption)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }
                Spacer()
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(RecordStore())
}
