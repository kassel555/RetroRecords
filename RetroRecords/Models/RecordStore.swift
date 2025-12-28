//
//  RecordStore.swift
//  RetroRecords
//
//  Main state container with JSON persistence
//

import Foundation
import SwiftUI

class RecordStore: ObservableObject {
    @Published var albums: [Album] = []
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateAdded
    @Published var filterGenre: String? = nil

    private let albumsFileName = "albums.json"

    // MARK: - Initialization

    init() {
        loadAlbums()
    }

    // MARK: - Computed Properties

    var filteredAlbums: [Album] {
        var result = albums

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { album in
                album.title.localizedCaseInsensitiveContains(searchText) ||
                album.artist.localizedCaseInsensitiveContains(searchText) ||
                album.genres.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Apply genre filter
        if let genre = filterGenre {
            result = result.filter { $0.genres.contains(genre) }
        }

        // Apply sorting
        switch sortOption {
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .artist:
            result.sort { $0.artist.localizedCompare($1.artist) == .orderedAscending }
        case .title:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .year:
            result.sort { ($0.releaseYear ?? 0) > ($1.releaseYear ?? 0) }
        case .condition:
            result.sort { $0.condition.sortOrder < $1.condition.sortOrder }
        }

        return result
    }

    var allGenres: [String] {
        Array(Set(albums.flatMap { $0.genres })).sorted()
    }

    var totalAlbums: Int {
        albums.count
    }

    // MARK: - CRUD Operations

    func addAlbum(_ album: Album) {
        albums.append(album)
        saveAlbums()
    }

    func updateAlbum(_ album: Album) {
        if let index = albums.firstIndex(where: { $0.id == album.id }) {
            albums[index] = album
            saveAlbums()
        }
    }

    func deleteAlbum(_ album: Album) {
        albums.removeAll { $0.id == album.id }
        deleteCoverImage(for: album)
        saveAlbums()
    }

    func deleteAlbums(at offsets: IndexSet) {
        let albumsToDelete = offsets.map { filteredAlbums[$0] }
        for album in albumsToDelete {
            deleteCoverImage(for: album)
            albums.removeAll { $0.id == album.id }
        }
        saveAlbums()
    }

    // MARK: - Persistence

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func saveAlbums() {
        let url = getDocumentsDirectory().appendingPathComponent(albumsFileName)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(albums)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            print("💾 Saved \(albums.count) albums")
        } catch {
            print("❌ Failed to save albums: \(error)")
        }
    }

    private func loadAlbums() {
        let url = getDocumentsDirectory().appendingPathComponent(albumsFileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("📁 No saved albums found, starting fresh")
            #if DEBUG
            // Load sample data in debug mode
            albums = Album.sampleAlbums
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            albums = try decoder.decode([Album].self, from: data)
            print("📂 Loaded \(albums.count) albums")
        } catch {
            print("❌ Failed to load albums: \(error)")
            albums = []
        }
    }

    // MARK: - Cover Image Management

    private func getCoversDirectory() -> URL {
        let coversURL = getDocumentsDirectory().appendingPathComponent("Covers")
        if !FileManager.default.fileExists(atPath: coversURL.path) {
            try? FileManager.default.createDirectory(at: coversURL, withIntermediateDirectories: true)
        }
        return coversURL
    }

    func saveCoverImage(_ imageData: Data, for albumId: UUID) -> URL? {
        let url = getCoversDirectory().appendingPathComponent("\(albumId.uuidString).jpg")
        do {
            try imageData.write(to: url)
            print("🖼️ Saved cover image for \(albumId)")
            return url
        } catch {
            print("❌ Failed to save cover: \(error)")
            return nil
        }
    }

    func loadCoverImage(for albumId: UUID) -> Data? {
        let url = getCoversDirectory().appendingPathComponent("\(albumId.uuidString).jpg")
        return try? Data(contentsOf: url)
    }

    private func deleteCoverImage(for album: Album) {
        let url = getCoversDirectory().appendingPathComponent("\(album.id.uuidString).jpg")
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case artist = "Artist"
    case title = "Title"
    case year = "Year"
    case condition = "Condition"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dateAdded: return "calendar"
        case .artist: return "person.fill"
        case .title: return "textformat"
        case .year: return "number"
        case .condition: return "star.fill"
        }
    }
}

// MARK: - Condition Sort Order

extension Condition {
    var sortOrder: Int {
        switch self {
        case .mint: return 0
        case .nearMint: return 1
        case .veryGoodPlus: return 2
        case .veryGood: return 3
        case .good: return 4
        case .fair: return 5
        case .poor: return 6
        }
    }
}
