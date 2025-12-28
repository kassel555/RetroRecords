//
//  RetroRecordsApp.swift
//  RetroRecords
//
//  Vinyl record collection tracker with 1970s aesthetic
//

import SwiftUI

@main
struct RetroRecordsApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var recordStore = RecordStore()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let currentUser = userManager.currentUser {
                    ContentView()
                        .environmentObject(recordStore)
                        .environmentObject(userManager)
                        .onAppear {
                            recordStore.switchUser(to: currentUser.id)
                        }
                        .onChange(of: userManager.currentUser?.id) { _, newId in
                            if let userId = newId {
                                recordStore.switchUser(to: userId)
                            }
                        }
                } else {
                    UserSelectionView(userManager: userManager)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
