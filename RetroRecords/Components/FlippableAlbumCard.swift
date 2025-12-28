//
//  FlippableAlbumCard.swift
//  RetroRecords
//
//  A flippable card showing album cover on front, track list on back
//

import SwiftUI

struct FlippableAlbumCard: View {
    let album: Album
    let size: CGFloat
    let colorScheme: ColorScheme

    @State private var isFlipped = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Back side (track list) - shown when flipped
            trackListSide
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )

            // Front side (album cover) - shown when not flipped
            coverSide
                .opacity(isFlipped ? 0 : 1)
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                rotation += 180
                isFlipped.toggle()
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Cover Side (Front)

    private var coverSide: some View {
        VStack(spacing: 0) {
            // Album cover image
            if let imageData = album.coverImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size - 40)
                    .clipped()
            } else if let urlString = album.coverImageURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    vinylPlaceholder
                }
                .frame(width: size, height: size - 40)
                .clipped()
            } else {
                vinylPlaceholder
                    .frame(width: size, height: size - 40)
            }

            // Tap hint
            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption2)
                Text("Tap to see tracks")
                    .font(.caption2)
            }
            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        }
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 8, x: 0, y: 4)
    }

    // MARK: - Track List Side (Back)

    private var trackListSide: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "music.note.list")
                Text("TRACK LIST")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))

            // Track list
            if album.trackList.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.5))
                    Text("No tracks available")
                        .font(.caption)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(album.trackList) { track in
                            trackRow(track)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }

            // Tap hint
            HStack {
                Image(systemName: "arrow.uturn.backward")
                    .font(.caption2)
                Text("Tap to flip back")
                    .font(.caption2)
            }
            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.8))
        }
        .background(RetroTheme.cork.opacity(0.3))
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 8, x: 0, y: 4)
    }

    // MARK: - Track Row

    private func trackRow(_ track: Track) -> some View {
        HStack(spacing: 8) {
            // Position badge
            Text(track.position)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 20)
                .background(RetroTheme.adaptiveAccent(for: colorScheme))
                .cornerRadius(4)

            // Track title
            Text(track.title)
                .font(.caption)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                .lineLimit(1)

            Spacer()

            // Duration
            if let duration = track.duration {
                Text(duration)
                    .font(.caption2)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        .cornerRadius(6)
    }

    // MARK: - Vinyl Placeholder

    private var vinylPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(RetroTheme.cork.opacity(0.3))

            ZStack {
                Circle()
                    .fill(RetroTheme.vinyl)
                    .frame(width: size * 0.6, height: size * 0.6)

                Circle()
                    .fill(RetroTheme.adaptiveAccent(for: colorScheme))
                    .frame(width: size * 0.2, height: size * 0.2)

                Circle()
                    .fill(RetroTheme.vinyl)
                    .frame(width: size * 0.06, height: size * 0.06)

                // Grooves
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(RetroTheme.vinyl.opacity(0.3), lineWidth: 1)
                        .frame(width: size * (0.3 + CGFloat(i) * 0.08),
                               height: size * (0.3 + CGFloat(i) * 0.08))
                }
            }
        }
    }
}

#Preview {
    VStack {
        FlippableAlbumCard(
            album: Album.sampleAlbums[0],
            size: 280,
            colorScheme: .light
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
