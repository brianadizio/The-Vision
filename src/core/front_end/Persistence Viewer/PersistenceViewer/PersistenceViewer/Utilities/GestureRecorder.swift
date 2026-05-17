//
//  GestureRecorder.swift
//  PersistenceViewer
//
//  Records gesture interaction events for export to The Golden Cipher and The Witness.
//  All VR hand gestures are timestamped and stored per-session as behavioral biometric data.
//
//  Restriction map: The Vision → The Golden Cipher (spatial_interaction_trajectory, jsonl)
//  Restriction map: The Vision → The Witness (session_log, jsonl)
//

import Foundation
import SwiftUI

// MARK: - Gesture Event Types

enum GestureEventType: String, Codable {
    case pinchSelect        // Pinch to select a persistence feature or point
    case dragRotate         // Drag to rotate 3D object
    case spreadZoom         // Pinch spread/pinch to zoom
    case tapAnnotate        // Tap to open annotation on a feature
    case sliceX             // Phase space slice along X axis
    case sliceY             // Phase space slice along Y axis
    case sliceZ             // Phase space slice along Z axis
    case bandNavigate       // Navigate to a frequency band
    case featureSelect      // Select a persistence diagram feature
    case viewReset          // Reset view to default
    case animationToggle    // Start/stop trajectory animation
    case dimensionToggle    // Toggle H0/H1/H2 visibility
    case so3Rotate          // Full SO(3) rotation state after drag (quaternion snapshot)
    case poincareSection    // Poincaré section computed at current slice plane
    case animationSpeed     // Animation playback speed changed
}

// MARK: - Gesture Event

struct GestureEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: GestureEventType
    let metadata: [String: String]

    init(type: GestureEventType, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.metadata = metadata
    }
}

// MARK: - Session Record (Golden Cipher / Witness export schema)

struct VisionSessionRecord: Codable {
    let sessionId: String
    let experimentLoaded: String
    let bandsViewed: Set<String>
    let visualizationsUsed: Set<String>
    let interactionEvents: [GestureEvent]
    let totalDurationMs: Int
    let startTime: Date
    let endTime: Date
    let annotationsMade: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case experimentLoaded = "experiment_loaded"
        case bandsViewed = "bands_viewed"
        case visualizationsUsed = "visualizations_used"
        case interactionEvents = "interaction_events"
        case totalDurationMs = "total_duration_ms"
        case startTime = "start_time"
        case endTime = "end_time"
        case annotationsMade = "annotations_made"
    }
}

// MARK: - Gesture Recorder

@MainActor
class GestureRecorder: ObservableObject {
    @Published private(set) var events: [GestureEvent] = []
    @Published var isRecording: Bool = true

    let sessionId: UUID = UUID()
    let sessionStart: Date = Date()

    private var bandsViewed: Set<String> = []
    private var visualizationsUsed: Set<String> = []
    private var annotationsMade: Int = 0

    // Record a gesture event
    func record(_ type: GestureEventType, metadata: [String: String] = [:]) {
        guard isRecording else { return }
        events.append(GestureEvent(type: type, metadata: metadata))
    }

    // Track which band was navigated to
    func trackBand(_ bandName: String) {
        bandsViewed.insert(bandName)
        record(.bandNavigate, metadata: ["band": bandName])
    }

    // Track which visualization was used
    func trackVisualization(_ name: String) {
        visualizationsUsed.insert(name)
    }

    // Track annotations
    func trackAnnotation() {
        annotationsMade += 1
    }

    // Build session record for export
    func buildSessionRecord(experimentName: String) -> VisionSessionRecord {
        let now = Date()
        let durationMs = Int(now.timeIntervalSince(sessionStart) * 1000)

        return VisionSessionRecord(
            sessionId: sessionId.uuidString,
            experimentLoaded: experimentName,
            bandsViewed: bandsViewed,
            visualizationsUsed: visualizationsUsed,
            interactionEvents: events,
            totalDurationMs: durationMs,
            startTime: sessionStart,
            endTime: now,
            annotationsMade: annotationsMade
        )
    }

    // Save session to assets/processed/vision_sessions/ as JSONL
    func saveSession(experimentName: String) {
        let record = buildSessionRecord(experimentName: experimentName)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(record) else { return }

        // Build output path
        let solutionRoot = "/Users/briandizio/Documents/2023-Now/Golden Enterprise Solutions/Solutions/The Vision"
        let sessionsDir = URL(fileURLWithPath: "\(solutionRoot)/assets/processed/vision_sessions")

        var isDir: ObjCBool = false
        let fm = FileManager.default
        if !fm.fileExists(atPath: sessionsDir.path, isDirectory: &isDir) {
            try? fm.createDirectory(at: sessionsDir, withIntermediateDirectories: true)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "session_\(formatter.string(from: sessionStart)).json"
        let outputURL = sessionsDir.appendingPathComponent(filename)

        try? data.write(to: outputURL)
    }

    // Clear events (for testing)
    func reset() {
        events = []
        bandsViewed = []
        visualizationsUsed = []
        annotationsMade = 0
    }

    var eventCount: Int { events.count }

    var lastEventDescription: String {
        guard let last = events.last else { return "No events" }
        return "\(last.type.rawValue) at \(last.timestamp.formatted(.dateTime.hour().minute().second()))"
    }
}

// MARK: - Gesture Event Count Badge

struct GestureEventBadge: View {
    @ObservedObject var recorder: GestureRecorder

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.raised.fingers.spread")
                .font(.caption)
                .foregroundColor(.coastalSecondary)
            Text("\(recorder.eventCount) events")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.tight)
    }
}
