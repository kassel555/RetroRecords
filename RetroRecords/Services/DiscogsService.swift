//
//  DiscogsService.swift
//  RetroRecords
//
//  Discogs API integration for album lookup
//

import Foundation

class DiscogsService {
    static let shared = DiscogsService()

    private let baseURL = "https://api.discogs.com"
    private let userAgent = "RetroRecords/1.0"

    private init() {}

    // MARK: - Search

    /// Search for releases matching a query
    func searchReleases(query: String, completion: @escaping (Result<[DiscogsSearchResult], Error>) -> Void) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.success([]))
            return
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/database/search?q=\(encodedQuery)&type=release&per_page=10"

        guard let url = URL(string: urlString) else {
            completion(.failure(DiscogsError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(DiscogsError.noData))
                }
                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(DiscogsSearchResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(searchResponse.results ?? []))
                }
            } catch {
                // Try to parse error response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(DiscogsError.apiError(message)))
                    }
                } else {
                    print("Discogs decode error: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }.resume()
    }

    // MARK: - Get Release Details

    /// Get full details for a specific release
    func getReleaseDetails(id: Int, completion: @escaping (Result<DiscogsRelease, Error>) -> Void) {
        let urlString = "\(baseURL)/releases/\(id)"

        guard let url = URL(string: urlString) else {
            completion(.failure(DiscogsError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(DiscogsError.noData))
                }
                return
            }

            do {
                let release = try JSONDecoder().decode(DiscogsRelease.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(release))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Download Cover Image

    /// Download cover image from URL
    func downloadCoverImage(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(DiscogsError.invalidURL))
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
                    completion(.failure(DiscogsError.noData))
                }
                return
            }

            DispatchQueue.main.async {
                completion(.success(data))
            }
        }.resume()
    }

    // MARK: - Convert to Album

    /// Convert a Discogs release to our Album model
    func convertToAlbum(from release: DiscogsRelease, coverImageData: Data? = nil) -> Album {
        let tracks = release.tracklist?.map { track in
            Track(
                position: track.position ?? "",
                title: track.title ?? "",
                duration: track.duration
            )
        } ?? []

        return Album(
            title: release.title ?? "Unknown Album",
            artist: release.artists?.first?.name ?? "Unknown Artist",
            releaseYear: release.year,
            label: release.labels?.first?.name,
            catalogNumber: release.labels?.first?.catno,
            genres: release.genres ?? [],
            trackList: tracks,
            coverImageData: coverImageData,
            coverImageURL: release.images?.first?.uri,
            condition: .veryGood,
            notes: "",
            discogsId: release.id
        )
    }

    enum DiscogsError: LocalizedError {
        case invalidURL
        case noData
        case rateLimited
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .noData: return "No data received"
            case .rateLimited: return "Too many requests. Please wait a moment."
            case .apiError(let message): return message
            }
        }
    }
}

// MARK: - Discogs API Response Models

struct DiscogsSearchResponse: Codable {
    let results: [DiscogsSearchResult]?
}

struct DiscogsSearchResult: Codable, Identifiable {
    let id: Int
    let title: String?
    let year: String?
    let country: String?
    let format: [String]?
    let label: [String]?
    let genre: [String]?
    let coverImage: String?
    let thumb: String?

    enum CodingKeys: String, CodingKey {
        case id, title, year, country, format, label, genre
        case coverImage = "cover_image"
        case thumb
    }

    var displayTitle: String {
        title ?? "Unknown"
    }

    var displayYear: String {
        year ?? ""
    }

    var displayLabel: String {
        label?.first ?? ""
    }

    var displayFormat: String {
        format?.first ?? "Vinyl"
    }
}

struct DiscogsRelease: Codable {
    let id: Int?
    let title: String?
    let year: Int?
    let artists: [DiscogsArtist]?
    let labels: [DiscogsLabel]?
    let genres: [String]?
    let styles: [String]?
    let tracklist: [DiscogsTrack]?
    let images: [DiscogsImage]?
}

struct DiscogsArtist: Codable {
    let name: String?
}

struct DiscogsLabel: Codable {
    let name: String?
    let catno: String?
}

struct DiscogsTrack: Codable {
    let position: String?
    let title: String?
    let duration: String?
}

struct DiscogsImage: Codable {
    let uri: String?
    let type: String?
}
