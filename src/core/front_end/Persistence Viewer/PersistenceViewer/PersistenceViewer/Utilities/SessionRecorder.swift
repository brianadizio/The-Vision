//
//  SessionRecorder.swift
//  PersistenceViewer
//
//  Full session recorder for VISION-006 restriction map exports.
//  Extends GestureRecorder with gaze (S2), hand positions (R3), and navigation path.
//
//  Restriction maps:
//    The Vision → The Golden Cipher  (spatial_interaction_trajectory, jsonl)
//    The Vision → The Witness        (session_log, jsonl)
//    The Vision → Data Phi Sheaf    (immersive_tda_export, json)
//

import Foundation
import SwiftUI

// MARK: - Gaze Sample (S2 spherical coordinates)

struct GazeSample: Codable {
    let timestamp: Date
    let azimuth: Double    // radians, 0–2π
    let elevation: Double  // radians, -π/2–π/2

    enum CodingKeys: String, CodingKey {
        case timestamp, azimuth, elevation
    }
}

// MARK: - Hand Sample (R3 position)

struct HandSample: Codable {
    let timestamp: Date
    let hand: String       // "left" or "right"
    let x: Double
    let y: Double
    let z: Double

    enum CodingKeys: String, CodingKey {
        case timestamp, hand, x, y, z
    }
}

// MARK: - Navigation Event

struct NavigationEvent: Codable {
    let timestamp: Date
    let level: String      // "experiment", "configuration", "band", "visualization"
    let name: String

    enum CodingKeys: String, CodingKey {
        case timestamp, level, name
    }
}

// MARK: - Full Session Data

struct FullSessionData: Codable {
    let sessionId: String
    let startTime: Date
    let endTime: Date
    let totalDurationMs: Int
    let experimentLoaded: String
    let gazeTrajectory: [GazeSample]
    let handPositions: [HandSample]
    let navigationPath: [NavigationEvent]
    let gestureEvents: [GestureEvent]
    let bandsViewed: [String]
    let visualizationsUsed: [String]
    let annotationsMade: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case totalDurationMs = "total_duration_ms"
        case experimentLoaded = "experiment_loaded"
        case gazeTrajectory = "gaze_trajectory"
        case handPositions = "hand_positions"
        case navigationPath = "navigation_path"
        case gestureEvents = "gesture_events"
        case bandsViewed = "bands_viewed"
        case visualizationsUsed = "visualizations_used"
        case annotationsMade = "annotations_made"
    }
}

// MARK: - Session Recorder

@MainActor
class SessionRecorder: ObservableObject {

    // Sub-recorder for gestures (shared with views)
    let gestureRecorder: GestureRecorder = GestureRecorder()

    @Published private(set) var gazeTrajectory: [GazeSample] = []
    @Published private(set) var handPositions: [HandSample] = []
    @Published private(set) var navigationPath: [NavigationEvent] = []

    private let sessionId: UUID = UUID()
    private let sessionStart: Date = Date()
    private var currentExperiment: String = "unknown"

    // MARK: - Gaze Tracking

    func recordGaze(azimuth: Double, elevation: Double) {
        gazeTrajectory.append(GazeSample(
            timestamp: Date(),
            azimuth: azimuth,
            elevation: elevation
        ))
    }

    // MARK: - Hand Tracking

    func recordHand(_ hand: String, x: Double, y: Double, z: Double) {
        handPositions.append(HandSample(
            timestamp: Date(),
            hand: hand,
            x: x, y: y, z: z
        ))
    }

    // MARK: - Navigation Tracking

    func navigated(to name: String, level: String) {
        navigationPath.append(NavigationEvent(
            timestamp: Date(),
            level: level,
            name: name
        ))
        if level == "experiment" { currentExperiment = name }
        if level == "band" { gestureRecorder.trackBand(name) }
        if level == "visualization" { gestureRecorder.trackVisualization(name) }
    }

    // MARK: - Build Full Session Data

    func buildFullSession() -> FullSessionData {
        let now = Date()
        let durationMs = Int(now.timeIntervalSince(sessionStart) * 1000)
        let sessionRecord = gestureRecorder.buildSessionRecord(experimentName: currentExperiment)

        return FullSessionData(
            sessionId: sessionId.uuidString,
            startTime: sessionStart,
            endTime: now,
            totalDurationMs: durationMs,
            experimentLoaded: currentExperiment,
            gazeTrajectory: gazeTrajectory,
            handPositions: handPositions,
            navigationPath: navigationPath,
            gestureEvents: gestureRecorder.events,
            bandsViewed: Array(sessionRecord.bandsViewed),
            visualizationsUsed: Array(sessionRecord.visualizationsUsed),
            annotationsMade: sessionRecord.annotationsMade
        )
    }

    // MARK: - Export

    func exportSession() {
        let session = buildFullSession()
        RestrictionMapExporter.export(session: session)
    }
}
