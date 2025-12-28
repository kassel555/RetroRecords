//
//  LastFMService.swift
//  RetroRecords
//
//  Last.fm API for artist biography and similar artists
//

import Foundation

class LastFMService {
    static let shared = LastFMService()

    private let baseURL = "https://ws.audioscrobbler.com/2.0/"

    // API key - users can get one free at https://www.last.fm/api/account/create
    private var apiKey: String {
        // Check UserDefaults for custom API key, fall back to demo key
        UserDefaults.standard.string(forKey: "lastfm_api_key") ?? "demo_key"
    }

    private init() {}

    // MARK: - Get Artist Info

    func getArtistInfo(artistName: String, completion: @escaping (Result<LastFMArtist, Error>) -> Void) {
        guard !artistName.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.failure(LastFMError.invalidArtistName))
            return
        }

        let encodedArtist = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artistName
        let urlString = "\(baseURL)?method=artist.getinfo&artist=\(encodedArtist)&api_key=\(apiKey)&format=json&autocorrect=1"

        guard let url = URL(string: urlString) else {
            completion(.failure(LastFMError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(LastFMError.noData))
                }
                return
            }

            do {
                // Check for API error response
                if let errorResponse = try? JSONDecoder().decode(LastFMErrorResponse.self, from: data),
                   errorResponse.error != nil {
                    DispatchQueue.main.async {
                        completion(.failure(LastFMError.apiError(errorResponse.message ?? "Unknown error")))
                    }
                    return
                }

                let response = try JSONDecoder().decode(LastFMArtistResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.artist))
                }
            } catch {
                print("Last.fm decode error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Set API Key

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "lastfm_api_key")
    }

    func hasValidAPIKey() -> Bool {
        let key = UserDefaults.standard.string(forKey: "lastfm_api_key") ?? ""
        return !key.isEmpty && key != "demo_key"
    }

    // MARK: - Errors

    enum LastFMError: LocalizedError {
        case invalidURL
        case noData
        case invalidArtistName
        case apiError(String)
        case noAPIKey

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .noData: return "No data received"
            case .invalidArtistName: return "Invalid artist name"
            case .apiError(let message): return message
            case .noAPIKey: return "No Last.fm API key configured"
            }
        }
    }
}

// MARK: - Last.fm API Response Models

struct LastFMArtistResponse: Codable {
    let artist: LastFMArtist
}

struct LastFMArtist: Codable {
    let name: String
    let mbid: String?
    let url: String?
    let image: [LastFMImage]?
    let stats: LastFMStats?
    let similar: LastFMSimilar?
    let tags: LastFMTags?
    let bio: LastFMBio?

    var formattedListeners: String {
        guard let listeners = stats?.listeners, let count = Int(listeners) else { return "N/A" }
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    var formattedPlaycount: String {
        guard let playcount = stats?.playcount, let count = Int(playcount) else { return "N/A" }
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    var similarArtistNames: [String] {
        similar?.artist?.compactMap { $0.name } ?? []
    }

    var tagNames: [String] {
        tags?.tag?.compactMap { $0.name } ?? []
    }

    var biographySummary: String {
        // Clean up HTML tags from biography
        let summary = bio?.summary ?? ""
        return summary
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var biographyFull: String {
        let content = bio?.content ?? ""
        return content
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var largestImageURL: String? {
        // Get the largest available image
        let sizes = ["mega", "extralarge", "large", "medium", "small"]
        for size in sizes {
            if let img = image?.first(where: { $0.size == size }), let url = img.url, !url.isEmpty {
                return url
            }
        }
        return image?.last?.url
    }
}

struct LastFMImage: Codable {
    let url: String?
    let size: String?

    enum CodingKeys: String, CodingKey {
        case url = "#text"
        case size
    }
}

struct LastFMStats: Codable {
    let listeners: String?
    let playcount: String?
}

struct LastFMSimilar: Codable {
    let artist: [LastFMSimilarArtist]?
}

struct LastFMSimilarArtist: Codable {
    let name: String?
    let url: String?
    let image: [LastFMImage]?
}

struct LastFMTags: Codable {
    let tag: [LastFMTag]?
}

struct LastFMTag: Codable {
    let name: String?
    let url: String?
}

struct LastFMBio: Codable {
    let published: String?
    let summary: String?
    let content: String?
}

struct LastFMErrorResponse: Codable {
    let error: Int?
    let message: String?
}
