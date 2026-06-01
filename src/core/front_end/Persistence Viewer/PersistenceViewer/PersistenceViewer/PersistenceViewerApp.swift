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
    // Owned at the App level so both the main window (EnvironmentPicker) and the
    // ImmersiveSpace skybox observe the same selected Nature environment. (VISION-002)
    @StateObject private var environmentManager = EnvironmentManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionRecorder)
                .environmentObject(environmentManager)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Auto-export restriction maps when app backgrounds
                Task { @MainActor in
                    sessionRecorder.exportSession()
                }
            }
        }

        // Immersive Nature backdrop. Opened on demand from ContentView so the
        // data visualizations float inside the selected Sachuest Point
        // environment (placeholder gradient skybox until PHYS-VISION-002/004
        // spatial captures land). (VISION-002)
        ImmersiveSpace(id: immersiveBackgroundID) {
            ImmersiveBackgroundView()
                .environmentObject(environmentManager)
        }
    }
}
