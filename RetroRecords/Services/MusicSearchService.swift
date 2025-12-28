//
//  MusicSearchService.swift
//  RetroRecords
//
//  iTunes Search API for finding albums (free, no auth required)
//

import Foundation

class MusicSearchService {
    static let shared = MusicSearchService()

    private let baseURL = "https://itunes.apple.com/search"

    private init() {}

    // MARK: - Search Albums

    func searchAlbums(query: String, completion: @escaping (Result<[MusicSearchResult], Error>) -> Void) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.success([]))
            return
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)?term=\(encodedQuery)&media=music&entity=album&limit=20"

        fetchAlbums(from: urlString, completion: completion)
    }

    // MARK: - Search Albums by Artist

    func searchAlbumsByArtist(artistName: String, completion: @escaping (Result<[MusicSearchResult], Error>) -> Void) {
        guard !artistName.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.success([]))
            return
        }

        let encodedArtist = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artistName
        let urlString = "\(baseURL)?term=\(encodedArtist)&media=music&entity=album&attribute=artistTerm&limit=50"

        fetchAlbums(from: urlString, completion: completion)
    }

    // MARK: - Fetch Albums (shared)

    private func fetchAlbums(from urlString: String, completion: @escaping (Result<[MusicSearchResult], Error>) -> Void) {

        guard let url = URL(string: urlString) else {
            completion(.failure(MusicSearchError.invalidURL))
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
                    completion(.failure(MusicSearchError.noData))
                }
                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(searchResponse.results))
                }
            } catch {
                print("iTunes decode error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Fetch Tracks for Album

    func fetchTracks(collectionId: Int, completion: @escaping (Result<[Track], Error>) -> Void) {
        let urlString = "https://itunes.apple.com/lookup?id=\(collectionId)&entity=song"

        guard let url = URL(string: urlString) else {
            completion(.failure(MusicSearchError.invalidURL))
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
                    completion(.failure(MusicSearchError.noData))
                }
                return
            }

            do {
                let lookupResponse = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)
                // Filter to only track results (skip the first collection result)
                let trackResults = lookupResponse.results.filter { $0.wrapperType == "track" }

                let tracks = trackResults.map { result -> Track in
                    // Convert track number to vinyl-style position (1-6 = A1-A6, 7+ = B1-Bx)
                    let trackNum = result.trackNumber ?? 0
                    let side = trackNum <= 6 ? "A" : "B"
                    let sideNum = trackNum <= 6 ? trackNum : trackNum - 6
                    let position = "\(side)\(sideNum)"

                    // Convert milliseconds to M:SS format
                    var duration: String? = nil
                    if let timeMs = result.trackTimeMillis {
                        let totalSeconds = timeMs / 1000
                        let minutes = totalSeconds / 60
                        let seconds = totalSeconds % 60
                        duration = String(format: "%d:%02d", minutes, seconds)
                    }

                    return Track(
                        position: position,
                        title: result.trackName ?? "Unknown Track",
                        duration: duration
                    )
                }

                DispatchQueue.main.async {
                    completion(.success(tracks))
                }
            } catch {
                print("iTunes lookup decode error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Download Cover Image

    func downloadCoverImage(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Get high-res artwork (replace 100x100 with 600x600)
        let highResURL = urlString.replacingOccurrences(of: "100x100", with: "600x600")

        guard let url = URL(string: highResURL) else {
            completion(.failure(MusicSearchError.invalidURL))
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
                    completion(.failure(MusicSearchError.noData))
                }
                return
            }

            DispatchQueue.main.async {
                completion(.success(data))
            }
        }.resume()
    }

    // MARK: - Convert to Album

    func convertToAlbum(from result: MusicSearchResult, coverImageData: Data? = nil, tracks: [Track] = []) -> Album {
        // Extract year from release date
        var releaseYear: Int? = nil
        if let releaseDate = result.releaseDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let date = formatter.date(from: releaseDate) {
                let calendar = Calendar.current
                releaseYear = calendar.component(.year, from: date)
            }
        }

        return Album(
            title: result.collectionName ?? "Unknown Album",
            artist: result.artistName ?? "Unknown Artist",
            releaseYear: releaseYear,
            label: nil,
            catalogNumber: nil,
            genres: result.primaryGenreName != nil ? [result.primaryGenreName!] : [],
            trackList: tracks,
            coverImageData: coverImageData,
            coverImageURL: result.artworkUrl100?.replacingOccurrences(of: "100x100", with: "600x600"),
            condition: .veryGood,
            notes: "",
            discogsId: nil
        )
    }

    // MARK: - Error

    enum MusicSearchError: LocalizedError {
        case invalidURL
        case noData

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .noData: return "No data received"
            }
        }
    }
}

// MARK: - iTunes API Response Models

struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [MusicSearchResult]
}

struct MusicSearchResult: Codable, Identifiable {
    var id: Int { collectionId ?? 0 }

    let collectionId: Int?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: String?
    let releaseDate: String?
    let primaryGenreName: String?
    let trackCount: Int?
    let collectionPrice: Double?
    let copyright: String?

    var displayTitle: String {
        collectionName ?? "Unknown Album"
    }

    var displayArtist: String {
        artistName ?? "Unknown Artist"
    }

    var displayYear: String {
        guard let releaseDate = releaseDate else { return "" }
        return String(releaseDate.prefix(4))
    }

    var highResArtworkURL: String? {
        artworkUrl100?.replacingOccurrences(of: "100x100", with: "600x600")
    }
}

// MARK: - iTunes Lookup Response (for fetching tracks)

struct iTunesLookupResponse: Codable {
    let resultCount: Int
    let results: [iTunesLookupResult]
}

struct iTunesLookupResult: Codable {
    let wrapperType: String?
    let trackName: String?
    let trackNumber: Int?
    let trackTimeMillis: Int?
    let discNumber: Int?
}
