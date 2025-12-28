//
//  ContentView.swift
//  RetroRecords
//
//  Main tab navigation for the app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            RetroTheme.adaptiveBackgroundGradient(for: colorScheme).ignoresSafeArea()

            TabView(selection: $selectedTab) {
                CollectionView()
                    .tabItem {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Collection")
                    }
                    .tag(0)

                ScanAlbumView()
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Scan")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .tint(RetroTheme.adaptiveAccent(for: colorScheme))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RecordStore())
}
