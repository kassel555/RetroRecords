//
//  User.swift
//  RetroRecords
//
//  User model for multi-user support
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var avatarEmoji: String
    var dateCreated: Date

    init(name: String, avatarEmoji: String = "🎵") {
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.dateCreated = Date()
    }
}

// MARK: - Avatar Options

extension User {
    static let avatarOptions = [
        "🎵", "🎶", "🎸", "🎷", "🎺", "🎹", "🥁", "🎤",
        "🎧", "📀", "💿", "🎼", "🎻", "🪗", "🪕", "🎚️"
    ]
}
