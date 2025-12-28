//
//  SearchAlbumView.swift
//  RetroRecords
//
//  Search for albums by artist name or album title using iTunes Search API
//

import SwiftUI

struct SearchAlbumView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var searchQuery = ""
    @State private var searchResults: [MusicSearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?
    @State private var isLoadingDetails = false

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            if !hasSearched {
                                searchPrompt
                            } else if searchResults.isEmpty && !isSearching {
                                noResultsView
                            } else {
                                searchResultsList
                            }
                        }
                        .padding()
                    }
                }

                // Loading overlay
                if isLoadingDetails {
                    loadingOverlay
                }
            }
            .navigationTitle("Search Albums")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                TextField("Artist or album name...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit {
                        performSearch()
                    }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                        hasSearched = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    }
                }
            }
            .padding(12)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(12)

            if isSearching {
                ProgressView()
                    .tint(RetroTheme.adaptiveAccent(for: colorScheme))
            } else {
                Button {
                    performSearch()
                } label: {
                    Text("Search")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(RetroTheme.adaptiveAccent(for: colorScheme))
                        .cornerRadius(12)
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
    }

    // MARK: - Search Prompt

    private var searchPrompt: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(RetroTheme.adaptiveCardBackground(for: colorScheme))
                    .frame(width: 120, height: 120)
                    .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 8, x: 0, y: 4)

                Image(systemName: "music.note.list")
                    .font(.system(size: 50))
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
            }

            VStack(spacing: 12) {
                Text("Find Your Records")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                Text("Search by artist name, album title,\nor both to find albums")
                    .font(.subheadline)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            // Example searches
            VStack(alignment: .leading, spacing: 12) {
                Text("Try searching for:")
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                HStack(spacing: 10) {
                    ForEach(["Pink Floyd", "Abbey Road", "Miles Davis"], id: \.self) { example in
                        Button {
                            searchQuery = example
                            performSearch()
                        } label: {
                            Text(example)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))
                                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding()
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(12)

            Spacer()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.5))

            Text("No albums found")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(RetroTheme.rust)
                    .padding()
                    .background(RetroTheme.rust.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(40)
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !searchResults.isEmpty {
                Text("\(searchResults.count) Results")
                    .font(.headline)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
            }

            ForEach(searchResults) { result in
                MusicResultRow(result: result, colorScheme: colorScheme) {
                    selectResult(result)
                }
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

    // MARK: - Actions

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        hasSearched = true
        errorMessage = nil

        MusicSearchService.shared.searchAlbums(query: query) { result in
            isSearching = false

            switch result {
            case .success(let results):
                searchResults = results
                if results.isEmpty {
                    errorMessage = "No albums found for \"\(query)\""
                }

            case .failure(let error):
                errorMessage = error.localizedDescription
                searchResults = []
            }
        }
    }

    private func selectResult(_ result: MusicSearchResult) {
        isLoadingDetails = true

        // Download cover image
        if let artworkURL = result.highResArtworkURL {
            MusicSearchService.shared.downloadCoverImage(from: artworkURL) { imageResult in
                isLoadingDetails = false

                let coverData: Data?
                switch imageResult {
                case .success(let data):
                    coverData = data
                case .failure:
                    coverData = nil
                }

                let album = MusicSearchService.shared.convertToAlbum(from: result, coverImageData: coverData)
                store.addAlbum(album)
                dismiss()
            }
        } else {
            isLoadingDetails = false
            let album = MusicSearchService.shared.convertToAlbum(from: result, coverImageData: nil)
            store.addAlbum(album)
            dismiss()
        }
    }
}

// MARK: - Music Result Row

struct MusicResultRow: View {
    let result: MusicSearchResult
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Thumbnail
                AsyncImage(url: URL(string: result.artworkUrl100 ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(RetroTheme.cork.opacity(0.3))
                        Image(systemName: "opticaldisc")
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                        .lineLimit(2)

                    Text(result.displayArtist)
                        .font(.caption)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if !result.displayYear.isEmpty {
                            Text(result.displayYear)
                                .font(.caption)
                                .foregroundColor(RetroTheme.mustard)
                        }

                        if let genre = result.primaryGenreName {
                            Text(genre)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))
                                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
            }
            .padding(12)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchAlbumView()
        .environmentObject(RecordStore())
}
