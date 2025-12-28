//
//  VinylCard.swift
//  RetroRecords
//
//  Polaroid-style album card with 1970s aesthetic
//

import SwiftUI

struct VinylCard: View {
    let album: Album
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Album cover with vintage frame
            ZStack {
                // Worn paper background
                RoundedRectangle(cornerRadius: 4)
                    .fill(RetroTheme.parchment)
                    .frame(height: 160)

                // Cover image or placeholder
                if let imageData = album.coverImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipped()
                        .cornerRadius(2)
                        .overlay(
                            // Vintage overlay
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    RetroTheme.caramel.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .cornerRadius(2)
                        )
                } else {
                    // Vinyl placeholder
                    ZStack {
                        Circle()
                            .fill(RetroTheme.vinyl)
                            .frame(width: 120, height: 120)

                        Circle()
                            .fill(RetroTheme.adaptiveAccent(for: colorScheme))
                            .frame(width: 40, height: 40)

                        Circle()
                            .fill(RetroTheme.vinyl)
                            .frame(width: 12, height: 12)

                        // Grooves
                        ForEach(0..<5, id: \.self) { i in
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                .frame(width: CGFloat(50 + i * 15), height: CGFloat(50 + i * 15))
                        }
                    }
                }
            }
            .frame(height: 160)
            .background(RetroTheme.parchment)

            // Album info section
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(1)

                Text(album.artist)
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    .lineLimit(1)

                HStack {
                    if let year = album.releaseYear {
                        Text("\(year)")
                            .font(.caption2)
                            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    }

                    Spacer()

                    Text(album.condition.emoji)
                        .font(.caption)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        }
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 4)
        .overlay(
            // Subtle worn edge effect
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            RetroTheme.caramel.opacity(0.3),
                            RetroTheme.caramel.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Compact Vinyl Card (for lists)

struct CompactVinylCard: View {
    let album: Album
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Mini cover
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(RetroTheme.parchment)
                    .frame(width: 60, height: 60)

                if let imageData = album.coverImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 54, height: 54)
                        .clipped()
                        .cornerRadius(4)
                } else {
                    Image(systemName: "opticaldisc.fill")
                        .font(.title2)
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(1)

                Text(album.artist)
                    .font(.subheadline)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let year = album.releaseYear {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundColor(RetroTheme.mustard)
                    }

                    Text(album.condition.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
        }
        .padding(12)
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            VinylCard(album: Album.sampleAlbums[0])
            VinylCard(album: Album.sampleAlbums[1])
        }
        .padding()

        CompactVinylCard(album: Album.sampleAlbums[0])
            .padding(.horizontal)
    }
    .background(RetroTheme.warmCream)
}
