//
//  ScanAlbumView.swift
//  RetroRecords
//
//  Camera view for scanning album covers with Vision + Discogs integration
//

import SwiftUI

struct ScanAlbumView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme

    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var searchResults: [DiscogsSearchResult] = []
    @State private var recognizedText: [String] = []
    @State private var searchQuery = ""
    @State private var showingResults = false
    @State private var showingAddSheet = false
    @State private var errorMessage: String?
    @State private var selectedResult: DiscogsSearchResult?
    @State private var isLoadingDetails = false

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if let image = capturedImage {
                            // Show captured image and results
                            capturedImageSection(image)
                        } else {
                            // Show scan prompt
                            scanPromptSection
                        }
                    }
                    .padding()
                }

                // Loading overlay
                if isProcessing || isLoadingDetails {
                    loadingOverlay
                }
            }
            .navigationTitle("Scan")
            .sheet(isPresented: $showingCamera) {
                CameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAlbumView()
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
        }
    }

    // MARK: - Scan Prompt Section

    private var scanPromptSection: some View {
        VStack(spacing: 30) {
            Spacer(minLength: 40)

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

                Text("Point your camera at an album cover\nto automatically find it on Discogs")
                    .font(.subheadline)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            // Scan button
            Button {
                showingCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Open Camera")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer(minLength: 20)

            // Manual add option
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Manually Instead")
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer(minLength: 40)
        }
    }

    // MARK: - Captured Image Section

    private func capturedImageSection(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            // Captured image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 200, height: 200)
                .cornerRadius(12)
                .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 8, x: 0, y: 4)

            // Recognized text
            if !recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recognized Text")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                    Text(recognizedText.prefix(5).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
                .cornerRadius(12)
            }

            // Search query editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Query")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                HStack {
                    TextField("Edit search query...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                    Button {
                        searchDiscogs()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                }
                .padding()
                .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
                .cornerRadius(10)
            }
            .padding()
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(12)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(RetroTheme.rust)
                    .padding()
                    .background(RetroTheme.rust.opacity(0.1))
                    .cornerRadius(8)
            }

            // Search results
            if !searchResults.isEmpty {
                searchResultsSection
            }

            // Action buttons
            HStack(spacing: 16) {
                Button {
                    resetScan()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Scan Again")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    showingAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Add Manually")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found \(searchResults.count) Results")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            ForEach(searchResults) { result in
                SearchResultRow(result: result, colorScheme: colorScheme) {
                    selectResult(result)
                }
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
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

                Text(isLoadingDetails ? "Loading album details..." : "Analyzing cover...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(16)
        }
    }

    // MARK: - Actions

    private func processImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil

        ImageRecognitionService.shared.recognizeText(from: image) { result in
            switch result {
            case .success(let texts):
                self.recognizedText = texts
                self.searchQuery = ImageRecognitionService.shared.buildSearchQuery(from: texts)

                if !self.searchQuery.isEmpty {
                    self.searchDiscogs()
                } else {
                    self.isProcessing = false
                    self.errorMessage = "Couldn't read text from the image. Try again or add manually."
                }

            case .failure(let error):
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func searchDiscogs() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isProcessing = true
        errorMessage = nil

        DiscogsService.shared.searchReleases(query: searchQuery) { result in
            self.isProcessing = false

            switch result {
            case .success(let results):
                self.searchResults = results
                if results.isEmpty {
                    self.errorMessage = "No albums found. Try editing the search query."
                }

            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func selectResult(_ result: DiscogsSearchResult) {
        isLoadingDetails = true

        DiscogsService.shared.getReleaseDetails(id: result.id) { detailResult in
            switch detailResult {
            case .success(let release):
                // Download cover image if available
                if let imageURL = release.images?.first?.uri {
                    DiscogsService.shared.downloadCoverImage(from: imageURL) { imageResult in
                        self.isLoadingDetails = false

                        let coverData: Data?
                        switch imageResult {
                        case .success(let data):
                            coverData = data
                        case .failure:
                            // Use captured image as fallback
                            coverData = self.capturedImage?.jpegData(compressionQuality: 0.8)
                        }

                        let album = DiscogsService.shared.convertToAlbum(from: release, coverImageData: coverData)
                        self.store.addAlbum(album)
                        self.resetScan()
                    }
                } else {
                    self.isLoadingDetails = false
                    // Use captured image
                    let coverData = self.capturedImage?.jpegData(compressionQuality: 0.8)
                    let album = DiscogsService.shared.convertToAlbum(from: release, coverImageData: coverData)
                    self.store.addAlbum(album)
                    self.resetScan()
                }

            case .failure(let error):
                self.isLoadingDetails = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func resetScan() {
        capturedImage = nil
        recognizedText = []
        searchResults = []
        searchQuery = ""
        errorMessage = nil
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: DiscogsSearchResult
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Thumbnail
                AsyncImage(url: URL(string: result.thumb ?? "")) { image in
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

                    HStack(spacing: 8) {
                        if !result.displayYear.isEmpty {
                            Text(result.displayYear)
                                .font(.caption)
                                .foregroundColor(RetroTheme.mustard)
                        }

                        Text(result.displayFormat)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.15))
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                            .cornerRadius(4)
                    }

                    if !result.displayLabel.isEmpty {
                        Text(result.displayLabel)
                            .font(.caption2)
                            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                            .lineLimit(1)
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
    ScanAlbumView()
        .environmentObject(RecordStore())
}
