//
//  RetroRecordsApp.swift
//  RetroRecords
//
//  Vinyl record collection tracker with 1970s aesthetic
//

import SwiftUI

@main
struct RetroRecordsApp: App {
    @StateObject private var recordStore = RecordStore()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recordStore)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
