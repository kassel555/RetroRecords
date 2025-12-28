//
//  CollectionView.swift
//  RetroRecords
//
//  Grid view of vinyl record collection
//

import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddSheet = false
    @State private var selectedAlbum: Album?
    @State private var showingSortMenu = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Stats header
                        if !store.albums.isEmpty {
                            statsHeader
                        }

                        // Album grid
                        if store.filteredAlbums.isEmpty {
                            emptyState
                        } else {
                            albumGrid
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Records")
            .searchable(text: $store.searchText, prompt: "Search albums...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                store.sortOption = option
                            } label: {
                                Label(option.rawValue, systemImage: option.icon)
                                if store.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAlbumView()
            }
            .sheet(item: $selectedAlbum) { album in
                AlbumDetailView(album: album)
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 20) {
            StatBadge(
                value: "\(store.totalAlbums)",
                label: "Records",
                icon: "opticaldisc.fill",
                colorScheme: colorScheme
            )

            StatBadge(
                value: "\(store.allGenres.count)",
                label: "Genres",
                icon: "music.note.list",
                colorScheme: colorScheme
            )
        }
        .padding(.bottom, 8)
    }

    // MARK: - Album Grid

    private var albumGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(store.filteredAlbums) { album in
                VinylCard(album: album)
                    .onTapGesture {
                        selectedAlbum = album
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "opticaldisc")
                .font(.system(size: 80))
                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.5))

            Text("No Records Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

            Text("Start building your collection by\nscanning an album cover or adding manually")
                .font(.subheadline)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Record")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                Text(label)
                    .font(.caption)
                    .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    CollectionView()
        .environmentObject(RecordStore())
}
