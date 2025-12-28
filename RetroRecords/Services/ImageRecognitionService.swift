//
//  ImageRecognitionService.swift
//  RetroRecords
//
//  Vision framework wrapper for album cover text recognition
//

import Vision
import UIKit

class ImageRecognitionService {
    static let shared = ImageRecognitionService()

    private init() {}

    /// Extract text from an image using Vision framework
    func recognizeText(from image: UIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(RecognitionError.invalidImage))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(.success([]))
                }
                return
            }

            // Extract top candidates from each observation
            let recognizedStrings = observations.compactMap { observation -> String? in
                observation.topCandidates(1).first?.string
            }

            DispatchQueue.main.async {
                completion(.success(recognizedStrings))
            }
        }

        // Configure for accurate recognition
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Parse recognized text to extract likely artist and album title
    func parseAlbumInfo(from texts: [String]) -> (artist: String?, title: String?) {
        // Filter out very short strings and common noise
        let meaningfulTexts = texts.filter { text in
            text.count >= 2 &&
            !text.lowercased().contains("stereo") &&
            !text.lowercased().contains("mono") &&
            !text.lowercased().contains("records") &&
            !text.lowercased().contains("rpm") &&
            !text.lowercased().contains("copyright")
        }

        // Heuristic: Larger/first text is often the title, second is artist
        // This is a simple approach - can be improved with ML
        guard !meaningfulTexts.isEmpty else {
            return (nil, nil)
        }

        if meaningfulTexts.count == 1 {
            // Single text - could be either
            return (nil, meaningfulTexts[0])
        }

        // Assume first is title, second is artist (common album cover layout)
        let title = meaningfulTexts[0]
        let artist = meaningfulTexts[1]

        return (artist, title)
    }

    /// Build a search query from recognized text
    func buildSearchQuery(from texts: [String]) -> String {
        let parsed = parseAlbumInfo(from: texts)

        var queryParts: [String] = []
        if let artist = parsed.artist {
            queryParts.append(artist)
        }
        if let title = parsed.title {
            queryParts.append(title)
        }

        // If parsing didn't work well, just use the first few recognized texts
        if queryParts.isEmpty && !texts.isEmpty {
            queryParts = Array(texts.prefix(3))
        }

        return queryParts.joined(separator: " ")
    }

    enum RecognitionError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process the image"
            }
        }
    }
}
