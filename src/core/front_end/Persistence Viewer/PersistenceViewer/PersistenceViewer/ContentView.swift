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
    @State private var showExportConfirmation = false

    var body: some View {
        ExperimentListView()
            .environmentObject(sessionRecorder)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sessionControlsButton
                }
            }
            .alert("Session Exported", isPresented: $showExportConfirmation) {
                Button("OK") {}
            } message: {
                Text("Session data exported to Golden Cipher, Witness, and Data Phi Sheaf.")
            }
    }

    private var sessionControlsButton: some View {
        Menu {
            Button {
                sessionRecorder.exportSession()
                showExportConfirmation = true
            } label: {
                Label("Export Session Now", systemImage: "arrow.up.doc")
            }

            Divider()

            Text("Session: \(sessionRecorder.gestureRecorder.eventCount) events")
        } label: {
            Label("Session", systemImage: "record.circle")
                .labelStyle(.iconOnly)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(SessionRecorder())
}
