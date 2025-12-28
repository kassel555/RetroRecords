//
//  ArtistAlbumsView.swift
//  RetroRecords
//
//  Browse all albums from a specific artist
//

import SwiftUI

struct ArtistAlbumsView: View {
    let artistName: String
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var albums: [MusicSearchResult] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isAddingAlbum = false

    // Track which albums are already in collection
    private var ownedAlbumTitles: Set<String> {
        Set(store.albums.filter { $0.artist.lowercased() == artistName.lowercased() }.map { $0.title.lowercased() })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if albums.isEmpty {
                    emptyView
                } else {
                    albumsGrid
                }

                if isAddingAlbum {
                    loadingOverlay
                }
            }
            .navigationTitle(artistName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }
        }
        .onAppear {
            fetchArtistAlbums()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(RetroTheme.adaptiveAccent(for: colorScheme))

            Text("Loading discography...")
                .font(.subheadline)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.mic")
                .font(.system(size: 50))
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.5))

            Text("No albums found")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(RetroTheme.rust)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding(40)
    }

    // MARK: - Albums Grid

    private var albumsGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with count
                HStack {
                    Image(systemName: "music.mic")
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    Text("\(albums.count) Albums")
                        .font(.headline)
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                    Spacer()

                    // Show count of owned albums
                    let ownedCount = albums.filter { isOwned($0) }.count
                    if ownedCount > 0 {
                        Text("\(ownedCount) in collection")
                            .font(.caption)
                            .foregroundColor(RetroTheme.mustard)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Grid of albums
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(albums) { album in
                        ArtistAlbumCard(
                            album: album,
                            isOwned: isOwned(album),
                            colorScheme: colorScheme
                        ) {
                            addAlbum(album)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Adding to collection...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(16)
        }
    }

    // MARK: - Helper Methods

    private func isOwned(_ album: MusicSearchResult) -> Bool {
        ownedAlbumTitles.contains(album.displayTitle.lowercased())
    }

    private func fetchArtistAlbums() {
        isLoading = true
        errorMessage = nil

        MusicSearchService.shared.searchAlbumsByArtist(artistName: artistName) { result in
            isLoading = false

            switch result {
            case .success(let results):
                // Sort by release date (newest first)
                self.albums = results.sorted { a, b in
                    (a.releaseDate ?? "") > (b.releaseDate ?? "")
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func addAlbum(_ result: MusicSearchResult) {
        guard !isOwned(result) else { return }

        isAddingAlbum = true
        let collectionId = result.collectionId ?? 0

        var fetchedTracks: [Track] = []
        var fetchedCoverData: Data? = nil
        let group = DispatchGroup()

        // Fetch tracks
        group.enter()
        MusicSearchService.shared.fetchTracks(collectionId: collectionId) { trackResult in
            if case .success(let tracks) = trackResult {
                fetchedTracks = tracks
            }
            group.leave()
        }

        // Download cover image
        if let artworkURL = result.highResArtworkURL {
            group.enter()
            MusicSearchService.shared.downloadCoverImage(from: artworkURL) { imageResult in
                if case .success(let data) = imageResult {
                    fetchedCoverData = data
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            isAddingAlbum = false
            let album = MusicSearchService.shared.convertToAlbum(
                from: result,
                coverImageData: fetchedCoverData,
                tracks: fetchedTracks
            )
            store.addAlbum(album)
        }
    }
}

// MARK: - Artist Album Card

struct ArtistAlbumCard: View {
    let album: MusicSearchResult
    let isOwned: Bool
    let colorScheme: ColorScheme
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Album artwork
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: album.artworkUrl100?.replacingOccurrences(of: "100x100", with: "300x300") ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(RetroTheme.cork.opacity(0.3))
                        Image(systemName: "opticaldisc")
                            .font(.largeTitle)
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)

                // Owned badge
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(RetroTheme.avocado)
                        .background(Circle().fill(.white).padding(2))
                        .padding(6)
                }
            }

            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.displayTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    if !album.displayYear.isEmpty {
                        Text(album.displayYear)
                            .font(.caption2)
                            .foregroundColor(RetroTheme.mustard)
                    }

                    Spacer()

                    if !isOwned {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 4, x: 0, y: 2)
        .opacity(isOwned ? 0.7 : 1)
    }
}

#Preview {
    ArtistAlbumsView(artistName: "Fleetwood Mac")
        .environmentObject(RecordStore())
}
