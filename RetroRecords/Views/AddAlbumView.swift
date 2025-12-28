//
//  AddAlbumView.swift
//  RetroRecords
//
//  Manual album entry form
//

import SwiftUI

struct AddAlbumView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var artist = ""
    @State private var releaseYear = ""
    @State private var label = ""
    @State private var catalogNumber = ""
    @State private var genres = ""
    @State private var condition: Condition = .veryGood
    @State private var notes = ""

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !artist.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Required fields
                        requiredFieldsSection

                        // Optional fields
                        optionalFieldsSection

                        // Condition picker
                        conditionSection

                        // Notes
                        notesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlbum()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? RetroTheme.adaptiveAccent(for: colorScheme) : RetroTheme.adaptiveTextSecondary(for: colorScheme))
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Required Fields Section

    private var requiredFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Required")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            VStack(spacing: 12) {
                RetroTextField(
                    title: "Album Title",
                    text: $title,
                    placeholder: "e.g., Rumours",
                    colorScheme: colorScheme
                )

                RetroTextField(
                    title: "Artist",
                    text: $artist,
                    placeholder: "e.g., Fleetwood Mac",
                    colorScheme: colorScheme
                )
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Optional Fields Section

    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optional Details")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            VStack(spacing: 12) {
                RetroTextField(
                    title: "Release Year",
                    text: $releaseYear,
                    placeholder: "e.g., 1977",
                    colorScheme: colorScheme,
                    keyboardType: .numberPad
                )

                RetroTextField(
                    title: "Record Label",
                    text: $label,
                    placeholder: "e.g., Warner Bros.",
                    colorScheme: colorScheme
                )

                RetroTextField(
                    title: "Catalog Number",
                    text: $catalogNumber,
                    placeholder: "e.g., BSK 3010",
                    colorScheme: colorScheme
                )

                RetroTextField(
                    title: "Genres",
                    text: $genres,
                    placeholder: "e.g., Rock, Pop (comma separated)",
                    colorScheme: colorScheme
                )
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Condition Section

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Condition")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Condition.allCases) { cond in
                    Button {
                        condition = cond
                    } label: {
                        HStack {
                            Text(cond.emoji)
                            Text(cond.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(condition == cond ?
                                    RetroTheme.adaptiveAccent(for: colorScheme) :
                                    RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
                        .foregroundColor(condition == cond ? .white : RetroTheme.adaptiveTextPrimary(for: colorScheme))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
        }
        .padding()
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
    }

    // MARK: - Save Album

    private func saveAlbum() {
        let genreList = genres
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let album = Album(
            title: title.trimmingCharacters(in: .whitespaces),
            artist: artist.trimmingCharacters(in: .whitespaces),
            releaseYear: Int(releaseYear),
            label: label.isEmpty ? nil : label.trimmingCharacters(in: .whitespaces),
            catalogNumber: catalogNumber.isEmpty ? nil : catalogNumber.trimmingCharacters(in: .whitespaces),
            genres: genreList,
            trackList: [],
            condition: condition,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )

        store.addAlbum(album)
        dismiss()
    }
}

// MARK: - Retro Text Field

struct RetroTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let colorScheme: ColorScheme
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(12)
                .background(RetroTheme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
        }
    }
}

#Preview {
    AddAlbumView()
        .environmentObject(RecordStore())
}
