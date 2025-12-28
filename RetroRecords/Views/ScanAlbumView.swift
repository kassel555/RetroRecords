//
//  ScanAlbumView.swift
//  RetroRecords
//
//  Camera view for scanning album covers (Phase 3)
//

import SwiftUI

struct ScanAlbumView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Camera icon
                    ZStack {
                        Circle()
                            .fill(RetroTheme.adaptiveCardBackground(for: colorScheme))
                            .frame(width: 160, height: 160)
                            .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 10, x: 0, y: 5)

                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 70))
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }

                    VStack(spacing: 12) {
                        Text("Scan Album Cover")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                        Text("Point your camera at an album cover\nto automatically add it to your collection")
                            .font(.subheadline)
                            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }

                    // Coming soon badge
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Coming Soon")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.mustard)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RetroTheme.mustard.opacity(0.15))
                    .cornerRadius(20)

                    Spacer()

                    // Add manually button
                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Manually Instead")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationTitle("Scan")
            .sheet(isPresented: $showingAddSheet) {
                AddAlbumView()
            }
        }
    }
}

#Preview {
    ScanAlbumView()
        .environmentObject(RecordStore())
}
