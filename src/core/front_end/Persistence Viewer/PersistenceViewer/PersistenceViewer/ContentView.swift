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
    @StateObject private var environmentManager = EnvironmentManager()
    @State private var showEnvironmentPicker = false
    @State private var showExportConfirmation = false

    var body: some View {
        ExperimentListView()
            .environmentObject(sessionRecorder)
            .environmentObject(environmentManager)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarItemGroup {
                        Button {
                            showEnvironmentPicker.toggle()
                        } label: {
                            Label("Environment", systemImage: "squa.fill.circle")
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
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(SessionRecorder())
}
