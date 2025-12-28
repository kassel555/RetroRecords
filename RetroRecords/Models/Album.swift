//
//  Album.swift
//  RetroRecords
//
//  Core data models for vinyl record collection
//

import Foundation

// MARK: - Album

struct Album: Identifiable, Codable {
    var id = UUID()
    var title: String
    var artist: String
    var releaseYear: Int?
    var label: String?
    var catalogNumber: String?
    var genres: [String]
    var trackList: [Track]
    var coverImageData: Data?
    var coverImageURL: String?
    var condition: Condition
    var notes: String
    var dateAdded: Date
    var discogsId: Int?
    var userRating: Int? // 1-5 star rating

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        releaseYear: Int? = nil,
        label: String? = nil,
        catalogNumber: String? = nil,
        genres: [String] = [],
        trackList: [Track] = [],
        coverImageData: Data? = nil,
        coverImageURL: String? = nil,
        condition: Condition = .veryGood,
        notes: String = "",
        dateAdded: Date = Date(),
        discogsId: Int? = nil,
        userRating: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.releaseYear = releaseYear
        self.label = label
        self.catalogNumber = catalogNumber
        self.genres = genres
        self.trackList = trackList
        self.coverImageData = coverImageData
        self.coverImageURL = coverImageURL
        self.condition = condition
        self.notes = notes
        self.dateAdded = dateAdded
        self.discogsId = discogsId
        self.userRating = userRating
    }
}

// MARK: - Track

struct Track: Identifiable, Codable {
    var id = UUID()
    var position: String
    var title: String
    var duration: String?

    init(id: UUID = UUID(), position: String, title: String, duration: String? = nil) {
        self.id = id
        self.position = position
        self.title = title
        self.duration = duration
    }
}

// MARK: - Condition

enum Condition: String, Codable, CaseIterable, Identifiable {
    case mint = "Mint"
    case nearMint = "Near Mint"
    case veryGoodPlus = "VG+"
    case veryGood = "VG"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .mint: return "Perfect, unplayed condition"
        case .nearMint: return "Nearly perfect with minimal signs of handling"
        case .veryGoodPlus: return "Shows some signs of play but well cared for"
        case .veryGood: return "Surface noise evident but still enjoyable"
        case .good: return "Significant wear, surface noise throughout"
        case .fair: return "Heavy wear, plays through with noise"
        case .poor: return "Barely playable, for collection only"
        }
    }

    var emoji: String {
        switch self {
        case .mint: return "💎"
        case .nearMint: return "✨"
        case .veryGoodPlus: return "👍"
        case .veryGood: return "👌"
        case .good: return "🤏"
        case .fair: return "😬"
        case .poor: return "💔"
        }
    }
}

// MARK: - Sample Data

extension Album {
    static let sampleAlbums: [Album] = [
        Album(
            title: "Rumours",
            artist: "Fleetwood Mac",
            releaseYear: 1977,
            label: "Warner Bros.",
            genres: ["Rock", "Pop Rock"],
            trackList: [
                Track(position: "A1", title: "Second Hand News", duration: "2:56"),
                Track(position: "A2", title: "Dreams", duration: "4:14"),
                Track(position: "A3", title: "Never Going Back Again", duration: "2:14"),
                Track(position: "A4", title: "Don't Stop", duration: "3:13"),
                Track(position: "A5", title: "Go Your Own Way", duration: "3:38")
            ],
            condition: .veryGoodPlus,
            notes: "Original pressing, slight ring wear on cover"
        ),
        Album(
            title: "Dark Side of the Moon",
            artist: "Pink Floyd",
            releaseYear: 1973,
            label: "Harvest",
            genres: ["Progressive Rock", "Psychedelic Rock"],
            trackList: [
                Track(position: "A1", title: "Speak to Me", duration: "1:30"),
                Track(position: "A2", title: "Breathe", duration: "2:43"),
                Track(position: "A3", title: "On the Run", duration: "3:30"),
                Track(position: "A4", title: "Time", duration: "6:53")
            ],
            condition: .nearMint,
            notes: "UK first pressing with posters"
        ),
        Album(
            title: "Abbey Road",
            artist: "The Beatles",
            releaseYear: 1969,
            label: "Apple Records",
            genres: ["Rock", "Pop"],
            trackList: [
                Track(position: "A1", title: "Come Together", duration: "4:20"),
                Track(position: "A2", title: "Something", duration: "3:03"),
                Track(position: "A3", title: "Maxwell's Silver Hammer", duration: "3:27")
            ],
            condition: .veryGood,
            notes: "1976 reissue"
        )
    ]
}
