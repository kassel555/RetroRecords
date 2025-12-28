//
//  ArtistInfoView.swift
//  RetroRecords
//
//  Display artist biography, stats, and similar artists from Last.fm
//

import SwiftUI

struct ArtistInfoView: View {
    let artistName: String
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var artistInfo: LastFMArtist?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAPIKeyPrompt = false
    @State private var apiKeyInput = ""
    @State private var chartEntries: [BillboardEntry] = []
    @State private var isLoadingChart = false

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let artist = artistInfo {
                    artistContent(artist)
                }
            }
            .navigationTitle("About the Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }
            .alert("Last.fm API Key", isPresented: $showingAPIKeyPrompt) {
                TextField("Enter API key", text: $apiKeyInput)
                Button("Save") {
                    LastFMService.shared.setAPIKey(apiKeyInput)
                    fetchArtistInfo()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Get a free API key at last.fm/api")
            }
        }
        .onAppear {
            fetchArtistInfo()
            fetchChartData()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(RetroTheme.adaptiveAccent(for: colorScheme))

            Text("Loading artist info...")
                .font(.subheadline)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(RetroTheme.mustard)

            Text("Couldn't load artist info")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            Text(error)
                .font(.subheadline)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if error.contains("Invalid API key") || error.contains("API key") {
                Button {
                    showingAPIKeyPrompt = true
                } label: {
                    HStack {
                        Image(systemName: "key")
                        Text("Set API Key")
                    }
                    .padding()
                    .background(RetroTheme.adaptiveAccent(for: colorScheme))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            Button {
                fetchArtistInfo()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
            }
            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
        }
        .padding()
    }

    // MARK: - Artist Content

    private func artistContent(_ artist: LastFMArtist) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with image and stats
                headerSection(artist)

                // Biography
                if !artist.biographySummary.isEmpty {
                    biographySection(artist)
                }

                // Tags/Genres
                if !artist.tagNames.isEmpty {
                    tagsSection(artist)
                }

                // Similar Artists
                if !artist.similarArtistNames.isEmpty {
                    similarArtistsSection(artist)
                }

                // Billboard Chart
                if !chartEntries.isEmpty || isLoadingChart {
                    billboardSection
                }

                // Last.fm link
                if let urlString = artist.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link")
                            Text("View on Last.fm")
                        }
                        .font(.subheadline)
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
    }

    // MARK: - Header Section

    private func headerSection(_ artist: LastFMArtist) -> some View {
        VStack(spacing: 16) {
            // Artist image
            if let imageURL = artist.largestImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(RetroTheme.cork.opacity(0.3))
                        Image(systemName: "music.mic")
                            .font(.system(size: 40))
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                }
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 8, x: 0, y: 4)
            } else {
                ZStack {
                    Circle()
                        .fill(RetroTheme.cork.opacity(0.3))
                        .frame(width: 150, height: 150)
                    Image(systemName: "music.mic")
                        .font(.system(size: 50))
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }

            // Artist name
            Text(artist.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            // Stats
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text(artist.formattedListeners)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    Text("Listeners")
                        .font(.caption)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }

                VStack(spacing: 4) {
                    Text(artist.formattedPlaycount)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(RetroTheme.mustard)
                    Text("Plays")
                        .font(.caption)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }
            }
            .padding()
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(12)
        }
    }

    // MARK: - Biography Section

    private func biographySection(_ artist: LastFMArtist) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                Text("Biography")
                    .font(.headline)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
            }

            Text(artist.biographySummary)
                .font(.body)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                .lineSpacing(4)

            if let published = artist.bio?.published, !published.isEmpty {
                Text("Last updated: \(published)")
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Tags Section

    private func tagsSection(_ artist: LastFMArtist) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                Text("Genres & Tags")
                    .font(.headline)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
            }

            FlowLayout(spacing: 8) {
                ForEach(artist.tagNames.prefix(10), id: \.self) { tag in
                    Text(tag)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Similar Artists Section

    private func similarArtistsSection(_ artist: LastFMArtist) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                Text("Similar Artists")
                    .font(.headline)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(artist.similarArtistNames.prefix(5), id: \.self) { name in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(RetroTheme.cork.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "music.mic")
                                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                            }

                            Text(name)
                                .font(.caption)
                                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 70)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Billboard Section

    private var billboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                Text("Billboard Hot 100")
                    .font(.headline)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
            }

            if isLoadingChart {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading chart data...")
                        .font(.caption)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }
                .padding(.vertical, 8)
            } else if chartEntries.isEmpty {
                Text("No songs currently on the Hot 100")
                    .font(.subheadline)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(chartEntries) { entry in
                        chartEntryRow(entry)
                    }
                }
            }

            Text("Data from Billboard Hot 100")
                .font(.caption2)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    private func chartEntryRow(_ entry: BillboardEntry) -> some View {
        HStack(spacing: 12) {
            // Position badge
            Text(entry.formattedPosition)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(RetroTheme.adaptiveAccent(for: colorScheme))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.song)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    // Peak position
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.to.line")
                            .font(.caption2)
                        Text(entry.formattedPeak)
                            .font(.caption)
                    }
                    .foregroundColor(RetroTheme.mustard)

                    // Weeks on chart
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(entry.formattedWeeks)
                            .font(.caption)
                    }
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }
            }

            Spacer()

            // Position change indicator
            Text(entry.positionChange)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(
                    entry.positionChangeColor == "up" ? RetroTheme.avocado :
                    entry.positionChangeColor == "down" ? RetroTheme.rust :
                    entry.positionChangeColor == "new" ? RetroTheme.mustard :
                    RetroTheme.adaptiveTextSecondary(for: colorScheme)
                )
        }
        .padding(10)
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        .cornerRadius(10)
    }

    // MARK: - Fetch Artist Info

    private func fetchArtistInfo() {
        isLoading = true
        errorMessage = nil

        LastFMService.shared.getArtistInfo(artistName: artistName) { result in
            isLoading = false

            switch result {
            case .success(let artist):
                artistInfo = artist
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Fetch Chart Data

    private func fetchChartData() {
        isLoadingChart = true

        BillboardService.shared.findArtistSongs(artistName: artistName) { result in
            isLoadingChart = false

            switch result {
            case .success(let entries):
                chartEntries = entries
            case .failure:
                // Silently fail - chart data is supplementary
                chartEntries = []
            }
        }
    }
}

#Preview {
    ArtistInfoView(artistName: "Fleetwood Mac")
}
