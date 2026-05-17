//
//  PersistenceViewerApp.swift
//  PersistenceViewer
//
//  Created by Brian DiZio on 10/11/25.
//

import SwiftUI

@main
struct PersistenceViewerApp: App {

    @StateObject private var sessionRecorder = SessionRecorder()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionRecorder)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Auto-export restriction maps when app backgrounds
                Task { @MainActor in
                    sessionRecorder.exportSession()
                }
            }
        }
    }
}
