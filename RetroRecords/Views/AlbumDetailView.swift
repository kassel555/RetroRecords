//
//  AlbumDetailView.swift
//  RetroRecords
//
//  Full album details view
//

import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Cover art
                        coverSection

                        // Album info
                        infoSection

                        // Track listing
                        if !album.trackList.isEmpty {
                            trackListSection
                        }

                        // Notes
                        if !album.notes.isEmpty {
                            notesSection
                        }

                        // Delete button
                        deleteButton
                    }
                    .padding()
                }
            }
            .navigationTitle(album.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }
            .alert("Delete Album", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    store.deleteAlbum(album)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to remove \"\(album.title)\" from your collection?")
            }
        }
    }

    // MARK: - Cover Section

    private var coverSection: some View {
        ZStack {
            // Vinyl peek effect
            Circle()
                .fill(RetroTheme.vinyl)
                .frame(width: 200, height: 200)
                .offset(x: 40, y: 0)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 5, y: 5)

            // Album cover
            if let imageData = album.coverImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 220, height: 220)
                    .cornerRadius(4)
                    .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 10, x: 0, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(RetroTheme.parchment)
                    .frame(width: 220, height: 220)
                    .overlay(
                        Image(systemName: "opticaldisc.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.5))
                    )
                    .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 16) {
            // Title and artist
            VStack(spacing: 6) {
                Text(album.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text(album.artist)
                    .font(.title3)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            }

            // Details row
            HStack(spacing: 20) {
                if let year = album.releaseYear {
                    DetailBadge(icon: "calendar", value: "\(year)", colorScheme: colorScheme)
                }

                DetailBadge(icon: "star.fill", value: album.condition.rawValue, colorScheme: colorScheme)

                if let label = album.label {
                    DetailBadge(icon: "building.2", value: label, colorScheme: colorScheme)
                }
            }

            // Genres
            if !album.genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(album.genres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))
                                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Track List Section

    private var trackListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Track Listing")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            VStack(spacing: 0) {
                ForEach(album.trackList) { track in
                    HStack {
                        Text(track.position)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                            .frame(width: 30, alignment: .leading)

                        Text(track.title)
                            .font(.subheadline)
                            .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                        Spacer()

                        if let duration = track.duration {
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)

                    if track.id != album.trackList.last?.id {
                        Divider()
                    }
                }
            }
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            Text(album.notes)
                .font(.body)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showingDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Remove from Collection")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(RetroTheme.rust)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RetroTheme.rust.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }
}

// MARK: - Detail Badge

struct DetailBadge: View {
    let icon: String
    let value: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    AlbumDetailView(album: Album.sampleAlbums[0])
        .environmentObject(RecordStore())
}
