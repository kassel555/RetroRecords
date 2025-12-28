//
//  StarRatingView.swift
//  RetroRecords
//
//  Interactive 5-star rating component
//

import SwiftUI

struct StarRatingView: View {
    let rating: Int?
    let maxRating: Int
    let colorScheme: ColorScheme
    let onRatingChanged: (Int?) -> Void

    init(
        rating: Int?,
        maxRating: Int = 5,
        colorScheme: ColorScheme,
        onRatingChanged: @escaping (Int?) -> Void
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.colorScheme = colorScheme
        self.onRatingChanged = onRatingChanged
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    if rating == star {
                        // Tap same star to clear rating
                        onRatingChanged(nil)
                    } else {
                        onRatingChanged(star)
                    }
                } label: {
                    Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(star <= (rating ?? 0) ? RetroTheme.mustard : RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Compact Star Rating (for display only)

struct CompactStarRating: View {
    let rating: Int?
    let colorScheme: ColorScheme

    var body: some View {
        if let rating = rating, rating > 0 {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundColor(star <= rating ? RetroTheme.mustard : RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.3))
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 3, colorScheme: .light) { _ in }
        StarRatingView(rating: nil, colorScheme: .light) { _ in }
        CompactStarRating(rating: 4, colorScheme: .light)
    }
    .padding()
}
