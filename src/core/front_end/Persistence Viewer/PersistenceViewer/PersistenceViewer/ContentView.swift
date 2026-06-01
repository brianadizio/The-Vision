//
//  ContentView.swift
//  PersistenceViewer
//
//  Created by Brian DiZio on 10/11/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @EnvironmentObject private var sessionRecorder: SessionRecorder
    // Provided by the App so the immersive skybox and the picker share one source
    // of truth for the selected Nature environment. (VISION-002)
    @EnvironmentObject private var environmentManager: EnvironmentManager

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var showEnvironmentPicker = false
    @State private var showExportConfirmation = false
    @State private var immersiveSpaceOpen = false

    var body: some View {
        ExperimentListView()
            .environmentObject(sessionRecorder)
            .environmentObject(environmentManager)
            // Requirement 5: keep chrome readable against the active Nature backdrop.
            .tint(environmentManager.currentEnvironment.recommendedForeground)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Toggle the immersive Sachuest Point backdrop on/off.
                    Button {
                        Task { await toggleImmersiveSpace() }
                    } label: {
                        Label(
                            immersiveSpaceOpen ? "Exit Nature View" : "Enter Nature View",
                            systemImage: immersiveSpaceOpen ? "mountain.2.fill" : "mountain.2"
                        )
                        .labelStyle(.iconOnly)
                    }

                    Button {
                        showEnvironmentPicker.toggle()
                    } label: {
                        Label("Environment", systemImage: "globe.americas.fill")
                            .labelStyle(.iconOnly)
                    }

                    Button {
                        sessionRecorder.exportSession()
                        showExportConfirmation = true
                    } label: {
                        Label("Export Session", systemImage: "arrow.up.doc")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .alert("Session Exported", isPresented: $showExportConfirmation) {
                Button("OK") {}
            } message: {
                Text("Session data exported to Golden Cipher, Witness, and Data Phi Sheaf.")
            }
            .sheet(isPresented: $showEnvironmentPicker) {
                NavigationView {
                    EnvironmentPicker()
                        .environmentObject(environmentManager)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showEnvironmentPicker.toggle()
                                }
                            }
                        }
                }
            }
    }

    // MARK: - Immersive Space Control

    /// Opens or dismisses the immersive Nature backdrop. The ImmersiveSpace is
    /// declared in PersistenceViewerApp and renders the currently-selected
    /// EnvironmentPreset as a skybox. (VISION-002)
    @MainActor
    private func toggleImmersiveSpace() async {
        if immersiveSpaceOpen {
            await dismissImmersiveSpace()
            immersiveSpaceOpen = false
        } else {
            switch await openImmersiveSpace(id: immersiveBackgroundID) {
            case .opened:
                immersiveSpaceOpen = true
            case .userCancelled, .error:
                immersiveSpaceOpen = false
            @unknown default:
                immersiveSpaceOpen = false
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(SessionRecorder())
        .environmentObject(EnvironmentManager())
}
