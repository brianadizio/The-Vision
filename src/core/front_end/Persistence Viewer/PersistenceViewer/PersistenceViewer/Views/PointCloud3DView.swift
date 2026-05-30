//
//  PointCloud3DView.swift
//  PersistenceViewer
//
//  3D point cloud visualization using RealityKit
//  Displays PCA-projected point clouds with interactive rotation and zoom
//

import SwiftUI
import RealityKit

struct PointCloud3DView: View {
    let pointCloud: PointCloudData
    let bandName: String
    var gestureRecorder: GestureRecorder? = nil  // injected from parent for session tracking
    /// Optional persistence diagram, used to drive per-feature spatial sonification.
    /// When non-nil, tapping a point also plays a Shepard tone from its 3D position.
    var persistenceFeatures: [PersistenceFeature]? = nil

    @State private var rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    @State private var scale: Float = 1.0
    @State private var showAxes: Bool = true
    @State private var pointSize: Float = 0.02

    // Pinch-select state
    @State private var selectedPointIndex: Int? = nil
    @State private var showSelectionInfo: Bool = false

    // Spatial audio
    @State private var audioEngine = SpatialAudioEngine()
    /// Cached normalised positions (matches what RealityKit renders) so the
    /// listener perceives audio coming from the same direction as the visual point.
    @State private var normalisedPositions: [SIMD3<Float>] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("3D Point Cloud")
                    .font(.headline)

                Spacer()

                // Controls
                HStack(spacing: 16) {
                    // Gesture event badge
                    if let recorder = gestureRecorder {
                        GestureEventBadge(recorder: recorder)
                    }

                    // Axes toggle
                    Button(action: {
                        withAnimation { showAxes.toggle() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showAxes ? "line.3.crossed.swirl.circle.fill" : "line.3.crossed.swirl.circle")
                            Text("Axes").font(.caption)
                        }
                        .foregroundColor(showAxes ? .coastalPrimary : .secondary)
                    }

                    // Reset view
                    Button(action: {
                        withAnimation {
                            rotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                            scale = 1.0
                            selectedPointIndex = nil
                        }
                        gestureRecorder?.record(.viewReset, metadata: ["view": "pointCloud"])
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset").font(.caption)
                        }
                    }

                    Divider().frame(height: 20)

                    // Spatial audio toggle (Shepard tones from feature positions)
                    Button(action: {
                        audioEngine.isActive.toggle()
                        if audioEngine.isActive {
                            audioEngine.startAmbient()
                        } else {
                            audioEngine.stopAll()
                        }
                    }) {
                        Image(systemName: audioEngine.isActive
                              ? "waveform.circle.fill"
                              : "waveform.circle")
                            .foregroundColor(audioEngine.isActive ? .coastalPrimary : .secondary)
                    }
                    .help("Spatial audio (Shepard tones)")

                    // Sequence: birth/death sweep through all persistence features
                    if let features = persistenceFeatures, !features.isEmpty {
                        Button(action: { playBirthDeathSequence(features: features) }) {
                            Image(systemName: "play.circle")
                                .foregroundColor(audioEngine.isActive ? .coastalPrimary : .secondary)
                        }
                        .disabled(!audioEngine.isActive)
                    }
                }
            }
            .padding()

            // Main 3D view
            RealityView { content in
                // Create point cloud entity
                if let pointCloudEntity = createPointCloudEntity(
                    points: pointCloud.simd3Points,
                    pointSize: pointSize
                ) {
                    content.add(pointCloudEntity)
                }

                // Add coordinate axes if enabled
                if showAxes {
                    if let axesEntity = createAxesEntity() {
                        content.add(axesEntity)
                    }
                }

                // Add lighting
                let light = DirectionalLight()
                light.light.intensity = 1000
                light.position = [0, 2, 2]
                light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
                content.add(light)

                // Add ambient light
                let ambient = PointLight()
                ambient.light.intensity = 500
                ambient.position = [0, 0, 0]
                content.add(ambient)

            } update: { content in
                // Update axes visibility
                content.entities.forEach { entity in
                    if entity.name == "axes" {
                        entity.isEnabled = showAxes
                    }

                    // Apply rotation and scale to point cloud
                    if entity.name == "pointCloud" {
                        entity.transform.rotation = rotation
                        entity.transform.scale = [scale, scale, scale]
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let sensitivity: Float = 0.01
                        let deltaX = Float(value.translation.width) * sensitivity
                        let deltaY = Float(value.translation.height) * sensitivity
                        let yawRotation = simd_quatf(angle: -deltaX, axis: [0, 1, 0])
                        let pitchRotation = simd_quatf(angle: deltaY, axis: [1, 0, 0])
                        rotation = (yawRotation * pitchRotation) * rotation
                    }
                    .onEnded { value in
                        let dx = Float(value.translation.width)
                        let dy = Float(value.translation.height)
                        gestureRecorder?.record(.dragRotate, metadata: [
                            "view": "pointCloud",
                            "band": bandName,
                            "dx": String(format: "%.1f", dx),
                            "dy": String(format: "%.1f", dy)
                        ])
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = Float(value)
                    }
                    .onEnded { value in
                        gestureRecorder?.record(.spreadZoom, metadata: [
                            "view": "pointCloud",
                            "band": bandName,
                            "scale": String(format: "%.2f", Float(value))
                        ])
                    }
            )
            .simultaneousGesture(
                // Pinch-select: tap to cycle through/select a point in the cloud
                TapGesture()
                    .onEnded {
                        let nextIndex = selectedPointIndex.map { ($0 + 1) % pointCloud.nPoints } ?? 0
                        selectedPointIndex = nextIndex
                        showSelectionInfo = true
                        gestureRecorder?.record(.pinchSelect, metadata: [
                            "view": "pointCloud",
                            "band": bandName,
                            "pointIndex": "\(nextIndex)",
                            "totalPoints": "\(pointCloud.nPoints)"
                        ])
                        sonifySelectedPoint(index: nextIndex)
                    }
            )

            // Selected point info
            if showSelectionInfo, let idx = selectedPointIndex, idx < pointCloud.points.count {
                let pt = pointCloud.points[idx]
                HStack(spacing: 16) {
                    Image(systemName: "scope")
                        .foregroundColor(.coastalAccent)
                        .font(.caption)
                    Text("Point \(idx + 1)")
                        .font(.caption).fontWeight(.medium)
                    Text(String(format: "(%.3f, %.3f, %.3f)", pt[0], pt.count > 1 ? pt[1] : 0, pt.count > 2 ? pt[2] : 0))
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button(action: {
                        withAnimation { showSelectionInfo = false; selectedPointIndex = nil }
                    }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.coastalAccent.opacity(0.08))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Info panel
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Points: \(pointCloud.nPoints)")
                        .font(.caption)
                    Spacer()
                    Text("Dimensions: \(pointCloud.dimensions)D")
                        .font(.caption)
                }

                // Scale slider
                HStack {
                    Text("Point Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $pointSize, in: 0.005...0.05, step: 0.005)
                        .frame(maxWidth: 200)
                    Text(String(format: "%.3f", pointSize))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }
            }
            .padding()
            .background(Color.coastalBackground)
        }
        .navigationTitle(bandName)
        .onAppear {
            normalisedPositions = normalizePoints(pointCloud.simd3Points)
        }
        .onDisappear {
            audioEngine.stopAll()
        }
    }

    // MARK: - Spatial Audio Helpers

    /// Map an arbitrary point index to a Shepard-tone burst from its normalised 3D location.
    private func sonifySelectedPoint(index: Int) {
        guard audioEngine.isActive,
              index >= 0,
              index < normalisedPositions.count else { return }
        let position = normalisedPositions[index]
        // Choose dimension by index third (rough proxy when no homology metadata).
        // If we have explicit persistence features, prefer those.
        let dimension: Int
        let lifetime: Double
        if let features = persistenceFeatures, !features.isEmpty {
            let feat = features[index % features.count]
            dimension = max(0, min(2, feat.dimension))
            lifetime = feat.lifetime ?? max(0.0, (feat.death ?? feat.birth) - feat.birth)
        } else {
            dimension = (index / max(1, normalisedPositions.count / 3)) % 3
            lifetime = 0.3
        }
        audioEngine.sonifyFeature(at: position,
                                  dimension: dimension,
                                  lifetime: lifetime,
                                  amplitudeScale: 0.8)
    }

    /// Play the full birth/death sequence using cached positions + features.
    private func playBirthDeathSequence(features: [PersistenceFeature]) {
        guard !normalisedPositions.isEmpty else { return }
        let positions = normalisedPositions
        let maxLifetime: Double = features.map { feat -> Double in
            if let lt = feat.lifetime { return lt }
            if let d = feat.death { return d - feat.birth }
            return 0.0
        }.max() ?? 1.0
        let payload: [(birth: Double,
                       death: Double?,
                       dimension: Int,
                       position: SIMD3<Float>)] = features.enumerated().map { (idx, f) in
            let pos = positions[idx % positions.count]
            return (birth: f.birth,
                    death: f.death,
                    dimension: max(0, min(2, f.dimension)),
                    position: pos)
        }
        audioEngine.sonifyBirthDeathSequence(features: payload, maxLifetime: maxLifetime)
    }

    // MARK: - RealityKit Entity Creation

    private func createPointCloudEntity(points: [SIMD3<Float>], pointSize: Float) -> ModelEntity? {
        guard !points.isEmpty else { return nil }

        // Normalize points to fit in unit cube
        let normalizedPoints = normalizePoints(points)

        // Create a parent entity to hold all point spheres
        let parentEntity = Entity()
        parentEntity.name = "pointCloud"

        // Create individual sphere for each point
        for (index, point) in normalizedPoints.enumerated() {
            var material = UnlitMaterial()
            material.color = .init(tint: colorForPoint(at: index, total: points.count))

            let sphere = ModelEntity(
                mesh: .generateSphere(radius: pointSize),
                materials: [material]
            )

            sphere.position = point
            parentEntity.addChild(sphere)
        }

        let container = ModelEntity(mesh: .generateBox(size: 0), materials: [])
        container.addChild(parentEntity)
        return container
    }

    private func createAxesEntity() -> Entity? {
        let axesEntity = Entity()
        axesEntity.name = "axes"

        let axisLength: Float = 0.6
        let axisRadius: Float = 0.005

        // X axis (red)
        var xMaterial = UnlitMaterial()
        xMaterial.color = .init(tint: .red)
        let xAxis = ModelEntity(
            mesh: .generateBox(size: [axisLength, axisRadius, axisRadius]),
            materials: [xMaterial]
        )
        xAxis.position = [axisLength / 2, 0, 0]
        axesEntity.addChild(xAxis)

        // Y axis (green)
        var yMaterial = UnlitMaterial()
        yMaterial.color = .init(tint: .green)
        let yAxis = ModelEntity(
            mesh: .generateBox(size: [axisRadius, axisLength, axisRadius]),
            materials: [yMaterial]
        )
        yAxis.position = [0, axisLength / 2, 0]
        axesEntity.addChild(yAxis)

        // Z axis (blue)
        var zMaterial = UnlitMaterial()
        zMaterial.color = .init(tint: .blue)
        let zAxis = ModelEntity(
            mesh: .generateBox(size: [axisRadius, axisRadius, axisLength]),
            materials: [zMaterial]
        )
        zAxis.position = [0, 0, axisLength / 2]
        axesEntity.addChild(zAxis)

        return axesEntity
    }

    // MARK: - Helper Functions

    private func normalizePoints(_ points: [SIMD3<Float>]) -> [SIMD3<Float>] {
        guard !points.isEmpty else { return points }

        // Find bounds
        var minX = Float.infinity, maxX = -Float.infinity
        var minY = Float.infinity, maxY = -Float.infinity
        var minZ = Float.infinity, maxZ = -Float.infinity

        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
            minZ = min(minZ, point.z)
            maxZ = max(maxZ, point.z)
        }

        // Calculate center and scale
        let center = SIMD3<Float>(
            (minX + maxX) / 2,
            (minY + maxY) / 2,
            (minZ + maxZ) / 2
        )

        let rangeX = maxX - minX
        let rangeY = maxY - minY
        let rangeZ = maxZ - minZ
        let maxRange = max(rangeX, rangeY, rangeZ)
        let scale: Float = maxRange > 0 ? 0.8 / maxRange : 1.0

        // Normalize points
        return points.map { point in
            (point - center) * scale
        }
    }

    private func colorForPoint(at index: Int, total: Int) -> UIColor {
        // Ocean depth gradient: deep ocean → mid ocean → coastal water → shallow water
        let ratio = Float(index) / Float(max(total - 1, 1))

        if ratio < 0.33 {
            // Deep ocean to mid ocean
            let t = ratio / 0.33
            return UIColor.interpolate(from: UIColor(Color.deepOcean), to: UIColor(Color.midOcean), progress: CGFloat(t))
        } else if ratio < 0.67 {
            // Mid ocean to coastal water
            let t = (ratio - 0.33) / 0.34
            return UIColor.interpolate(from: UIColor(Color.midOcean), to: UIColor(Color.coastalWater), progress: CGFloat(t))
        } else {
            // Coastal water to shallow water
            let t = (ratio - 0.67) / 0.33
            return UIColor.interpolate(from: UIColor(Color.coastalWater), to: UIColor(Color.shallowWater), progress: CGFloat(t))
        }
    }
}

// MARK: - Preview

#Preview {
    // Sample point cloud data
    let samplePoints: [[Double]] = (0..<100).map { i in
        let t = Double(i) / 100.0 * 2 * .pi
        return [
            cos(t) + Double.random(in: -0.1...0.1),
            sin(t) + Double.random(in: -0.1...0.1),
            Double(i) / 50.0 - 1.0 + Double.random(in: -0.1...0.1)
        ]
    }

    let samplePointCloud = PointCloudData(
        points: samplePoints,
        nPoints: 100,
        dimensions: 3
    )

    NavigationStack {
        PointCloud3DView(
            pointCloud: samplePointCloud,
            bandName: "Band 01"
        )
    }
}
