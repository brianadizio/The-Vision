//
//  RestrictionMapExporter.swift
//  PersistenceViewer
//
//  Exports VR session data to three restriction map destinations:
//    1. Golden Cipher  → assets/processed/golden_cipher/trajectory_*.jsonl
//    2. Witness        → assets/processed/witness/session_*.jsonl
//    3. Data Phi Sheaf → assets/processed/data_phi_sheaf/annotations_*.json
//
//  Call RestrictionMapExporter.export(session:) at session end.
//

import Foundation

enum RestrictionMapExporter {

    private static let solutionRoot =
        "/Users/briandizio/Documents/2023-Now/Golden Enterprise Solutions/Solutions/The Vision"

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let lineEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Public Entry Point

    static func export(session: FullSessionData) {
        exportGoldenCipher(session: session)
        exportWitness(session: session)
        exportDataPhiSheaf(session: session)
    }

    // MARK: - 1. Golden Cipher (behavioral trajectory jsonl)
    //
    // One line per interaction event: timestamp, event type, gaze position, hand positions.
    // Destination: The Golden Cipher spatial_interaction_trajectory restriction map.

    private static func exportGoldenCipher(session: FullSessionData) {
        let dir = makeDir("golden_cipher")
        let filename = "trajectory_\(filenameTimestamp(session.startTime)).jsonl"
        let url = dir.appendingPathComponent(filename)

        // Build a JSONL body — one JSON object per line
        var lines: [String] = []

        // Header line with session metadata
        let header: [String: Any] = [
            "record_type": "session_header",
            "session_id": session.sessionId,
            "experiment": session.experimentLoaded,
            "start_time": iso8601(session.startTime),
            "end_time": iso8601(session.endTime),
            "duration_ms": session.totalDurationMs
        ]
        if let headerLine = jsonLine(header) { lines.append(headerLine) }

        // One line per gesture event with nearest gaze sample interpolated
        for event in session.gestureEvents {
            let nearestGaze = nearestGazeSample(to: event.timestamp, in: session.gazeTrajectory)
            var record: [String: Any] = [
                "record_type": "gesture_event",
                "session_id": session.sessionId,
                "timestamp": iso8601(event.timestamp),
                "event_type": event.type.rawValue,
                "metadata": event.metadata
            ]
            if let gaze = nearestGaze {
                record["gaze_azimuth"] = gaze.azimuth
                record["gaze_elevation"] = gaze.elevation
            }
            if let line = jsonLine(record) { lines.append(line) }
        }

        // One line per navigation event
        for nav in session.navigationPath {
            let navRecord: [String: Any] = [
                "record_type": "navigation_event",
                "session_id": session.sessionId,
                "timestamp": iso8601(nav.timestamp),
                "level": nav.level,
                "name": nav.name
            ]
            if let line = jsonLine(navRecord) { lines.append(line) }
        }

        // Gaze trajectory summary (sampled at 1Hz to keep file small)
        let sampledGaze = stride(from: 0, to: session.gazeTrajectory.count, by: max(1, session.gazeTrajectory.count / 60))
            .map { session.gazeTrajectory[$0] }
        for sample in sampledGaze {
            let gazeRecord: [String: Any] = [
                "record_type": "gaze_sample",
                "session_id": session.sessionId,
                "timestamp": iso8601(sample.timestamp),
                "azimuth": sample.azimuth,
                "elevation": sample.elevation
            ]
            if let line = jsonLine(gazeRecord) { lines.append(line) }
        }

        let content = lines.joined(separator: "\n")
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - 2. Witness (session audit log jsonl)
    //
    // Audit trail: session metadata + ordered list of all events.
    // Destination: The Witness session_log restriction map.

    private static func exportWitness(session: FullSessionData) {
        let dir = makeDir("witness")
        let filename = "session_\(filenameTimestamp(session.startTime)).jsonl"
        let url = dir.appendingPathComponent(filename)

        var lines: [String] = []

        // Session summary
        let summary: [String: Any] = [
            "record_type": "session_summary",
            "session_id": session.sessionId,
            "start_time": iso8601(session.startTime),
            "end_time": iso8601(session.endTime),
            "duration_ms": session.totalDurationMs,
            "experiment_loaded": session.experimentLoaded,
            "bands_viewed_count": session.bandsViewed.count,
            "bands_viewed": session.bandsViewed,
            "visualizations_used": session.visualizationsUsed,
            "gesture_event_count": session.gestureEvents.count,
            "annotations_made": session.annotationsMade,
            "gaze_samples_recorded": session.gazeTrajectory.count,
            "hand_samples_recorded": session.handPositions.count
        ]
        if let line = jsonLine(summary) { lines.append(line) }

        // Navigation path
        for nav in session.navigationPath {
            let navRecord: [String: Any] = [
                "record_type": "navigation",
                "session_id": session.sessionId,
                "timestamp": iso8601(nav.timestamp),
                "level": nav.level,
                "name": nav.name
            ]
            if let line = jsonLine(navRecord) { lines.append(line) }
        }

        // Gesture events (compact)
        for event in session.gestureEvents {
            var record: [String: Any] = [
                "record_type": "gesture",
                "session_id": session.sessionId,
                "timestamp": iso8601(event.timestamp),
                "type": event.type.rawValue
            ]
            if !event.metadata.isEmpty { record["metadata"] = event.metadata }
            if let line = jsonLine(record) { lines.append(line) }
        }

        let content = lines.joined(separator: "\n")
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - 3. Data Phi Sheaf (annotated persistence diagrams json)
    //
    // Session metadata + annotations made during exploration.
    // Destination: Data Phi Sheaf immersive_tda_export restriction map.

    private static func exportDataPhiSheaf(session: FullSessionData) {
        let dir = makeDir("data_phi_sheaf")
        let filename = "annotations_\(filenameTimestamp(session.startTime)).json"
        let url = dir.appendingPathComponent(filename)

        let tapEvents = session.gestureEvents.filter { $0.type == .tapAnnotate }
        let annotations: [[String: Any]] = tapEvents.map { event in
            let ts: String = iso8601(event.timestamp)
            let feature: String = event.metadata["feature"] ?? "unknown"
            let annotation: String = event.metadata["annotation"] ?? ""
            let hClass: String = event.metadata["homologyClass"] ?? "unknown"
            return ["timestamp": ts, "feature": feature, "annotation": annotation, "homology_class": hClass]
        }

        let payload: [String: Any] = [
            "schema_version": "1.0",
            "session_id": session.sessionId,
            "experiment_loaded": session.experimentLoaded,
            "start_time": iso8601(session.startTime),
            "end_time": iso8601(session.endTime),
            "bands_explored": session.bandsViewed,
            "visualizations_used": session.visualizationsUsed,
            "annotations": annotations,
            "annotation_count": annotations.count,
            "source": "the_vision_visionpro"
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: url)
        }
    }

    // MARK: - Helpers

    private static func makeDir(_ name: String) -> URL {
        let url = URL(fileURLWithPath: "\(solutionRoot)/assets/processed/\(name)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func filenameTimestamp(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd_HHmmss"
        return fmt.string(from: date)
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func jsonLine(_ dict: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func nearestGazeSample(to date: Date, in samples: [GazeSample]) -> GazeSample? {
        guard !samples.isEmpty else { return nil }
        return samples.min(by: {
            abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
        })
    }
}
