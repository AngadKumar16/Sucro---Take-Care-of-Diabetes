//
//  DiabetesCareWatchApp.swift
//  DiabetesCare Watch
//
//  Glucose on the wrist, and the few things worth doing from a watch:
//  log fast sugar for a low (with the recheck countdown), log a quick
//  glucose check or carbs, and the steps for a low. Everything goes
//  through the phone, which keeps the log.
//

import SwiftUI

@main
struct DiabetesCareWatchApp: App {
    @State private var store = WatchStore.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(store)
                .onAppear { store.start() }
        }
    }
}
