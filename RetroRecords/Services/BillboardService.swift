//
//  BillboardService.swift
//  RetroRecords
//
//  Billboard Hot 100 chart data from open source GitHub repository
//  Data source: github.com/mhollingshead/billboard-hot-100
//

import Foundation

class BillboardService {
    static let shared = BillboardService()

    // GitHub raw URLs for Billboard Hot 100 data
    private let recentChartURL = "https://raw.githubusercontent.com/mhollingshead/billboard-hot-100/main/recent.json"
    private let historicalBaseURL = "https://raw.githubusercontent.com/mhollingshead/billboard-hot-100/main/date/"

    // Cache for chart data
    private var cachedChart: BillboardChart?
    private var cacheDate: Date?
    private let cacheExpiry: TimeInterval = 3600 // 1 hour

    private init() {}

    // MARK: - Fetch Current Chart

    func fetchCurrentChart(completion: @escaping (Result<BillboardChart, Error>) -> Void) {
        // Check cache
        if let cached = cachedChart,
           let cacheTime = cacheDate,
           Date().timeIntervalSince(cacheTime) < cacheExpiry {
            completion(.success(cached))
            return
        }

        guard let url = URL(string: recentChartURL) else {
            completion(.failure(BillboardError.invalidURL))
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
                    completion(.failure(BillboardError.noData))
                }
                return
            }

            do {
                let chart = try JSONDecoder().decode(BillboardChart.self, from: data)
                self.cachedChart = chart
                self.cacheDate = Date()

                DispatchQueue.main.async {
                    completion(.success(chart))
                }
            } catch {
                print("Billboard decode error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Search for Song on Chart

    func findSongOnChart(title: String, artist: String, completion: @escaping (Result<BillboardEntry?, Error>) -> Void) {
        fetchCurrentChart { result in
            switch result {
            case .success(let chart):
                // Search for matching song (case-insensitive partial match)
                let normalizedTitle = title.lowercased()
                let normalizedArtist = artist.lowercased()

                let match = chart.data.first { entry in
                    let songMatch = entry.song.lowercased().contains(normalizedTitle) ||
                                   normalizedTitle.contains(entry.song.lowercased())
                    let artistMatch = entry.artist.lowercased().contains(normalizedArtist) ||
                                     normalizedArtist.contains(entry.artist.lowercased())
                    return songMatch && artistMatch
                }

                completion(.success(match))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Find Artist's Charting Songs

    func findArtistSongs(artistName: String, completion: @escaping (Result<[BillboardEntry], Error>) -> Void) {
        fetchCurrentChart { result in
            switch result {
            case .success(let chart):
                let normalizedArtist = artistName.lowercased()

                let matches = chart.data.filter { entry in
                    entry.artist.lowercased().contains(normalizedArtist) ||
                    normalizedArtist.contains(entry.artist.lowercased())
                }

                completion(.success(matches))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Fetch Historical Chart

    func fetchChartForDate(_ date: Date, completion: @escaping (Result<BillboardChart, Error>) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let urlString = "\(historicalBaseURL)\(dateString).json"

        guard let url = URL(string: urlString) else {
            completion(.failure(BillboardError.invalidURL))
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
                    completion(.failure(BillboardError.noData))
                }
                return
            }

            do {
                let chart = try JSONDecoder().decode(BillboardChart.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(chart))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(BillboardError.chartNotFound))
                }
            }
        }.resume()
    }

    // MARK: - Errors

    enum BillboardError: LocalizedError {
        case invalidURL
        case noData
        case chartNotFound

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .noData: return "No data received"
            case .chartNotFound: return "Chart not found for this date"
            }
        }
    }
}

// MARK: - Billboard Data Models

struct BillboardChart: Codable {
    let date: String
    let data: [BillboardEntry]
}

struct BillboardEntry: Codable, Identifiable {
    let song: String
    let artist: String
    let thisWeek: Int
    let lastWeek: Int?
    let peakPosition: Int
    let weeksOnChart: Int

    var id: String { "\(song)-\(artist)" }

    enum CodingKeys: String, CodingKey {
        case song
        case artist
        case thisWeek = "this_week"
        case lastWeek = "last_week"
        case peakPosition = "peak_position"
        case weeksOnChart = "weeks_on_chart"
    }

    // Display helpers
    var positionChange: String {
        guard let last = lastWeek else { return "NEW" }
        let change = last - thisWeek
        if change > 0 {
            return "▲\(change)"
        } else if change < 0 {
            return "▼\(abs(change))"
        }
        return "—"
    }

    var positionChangeColor: String {
        guard let last = lastWeek else { return "new" }
        let change = last - thisWeek
        if change > 0 { return "up" }
        if change < 0 { return "down" }
        return "same"
    }

    var formattedPosition: String {
        "#\(thisWeek)"
    }

    var formattedPeak: String {
        "Peak: #\(peakPosition)"
    }

    var formattedWeeks: String {
        weeksOnChart == 1 ? "1 week" : "\(weeksOnChart) weeks"
    }
}
