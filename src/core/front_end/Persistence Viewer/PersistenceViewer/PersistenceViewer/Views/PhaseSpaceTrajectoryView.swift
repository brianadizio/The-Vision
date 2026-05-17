//
//  PhaseSpaceTrajectoryView.swift
//  PersistenceViewer
//
//  3D phase space trajectory visualization
//  Shows circular phase space evolution across frequency bands
//

import SwiftUI
import RealityKit

struct PhaseSpaceTrajectoryView: View {
    let phaseSpace: VisualizationData
    let experimentName: String
    var dataSource: String? = nil        // e.g. "SSEUQFT", "Mobius Band" — shown in header
    var gestureRecorder: GestureRecorder? = nil  // injected for session tracking

    @State private var rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    @State private var scale: Float = 1.0
    @State private var showAxes: Bool = true
    @State private var showTrail: Bool = true
    @State private var animationProgress: Double = 1.0
    @State private var isAnimating: Bool = false
    @State private var selectedBand: Int = 0
    @State private var showAllBands: Bool = true

    // Animation speed multiplier: 0.5×, 1×, 2×, 4×
    @State private var animationSpeed: Double = 1.0
    private let speedOptions: [Double] = [0.5, 1.0, 2.0, 4.0]

    // Slicing plane: cut trajectory along one axis at a threshold
    @State private var sliceEnabled: Bool = false
    @State private var sliceAxis: SliceAxis = .y
    @State private var sliceThreshold: Float = 0.0

    // Poincaré section: 2D cross-section at slice plane
    @State private var showPoincareSection: Bool = false
    private let poincareEpsilon: Float = 0.05  // half-width of the slab

    enum SliceAxis: String, CaseIterable {
        case x = "X", y = "Y", z = "Z"
    }

    // Assuming 100 points per band across 20 bands = 2000 total points
    private let pointsPerBand = 100
    private var numberOfBands: Int {
        phaseSpace.nPoints / pointsPerBand
    }

    var visiblePoints: [SIMD3<Float>] {
        let points = phaseSpace.simd3Points
        var base: [SIMD3<Float>]

        if showAllBands {
            let endIndex = Int(Double(points.count) * animationProgress)
            base = Array(points.prefix(endIndex))
        } else {
            let startIndex = selectedBand * pointsPerBand
            let endIndex = min(startIndex + pointsPerBand, points.count)
            guard startIndex < points.count else { return [] }
            base = Array(points[startIndex..<endIndex])
        }

        // Apply slice filter: keep points on the positive side of the slice plane
        if sliceEnabled {
            base = base.filter { pt in
                switch sliceAxis {
                case .x: return pt.x >= sliceThreshold
                case .y: return pt.y >= sliceThreshold
                case .z: return pt.z >= sliceThreshold
                }
            }
        }

        return base
    }

    /// Points within epsilon of the slice plane — the Poincaré section.
    /// Projects onto the two axes perpendicular to the slice axis.
    var poincarePoints: [(Float, Float)] {
        guard sliceEnabled else { return [] }
        let all = phaseSpace.simd3Points
        return all.compactMap { pt in
            let coord: Float
            let u: Float
            let v: Float
            switch sliceAxis {
            case .x: coord = pt.x; u = pt.y; v = pt.z
            case .y: coord = pt.y; u = pt.x; v = pt.z
            case .z: coord = pt.z; u = pt.x; v = pt.y
            }
            guard abs(coord - sliceThreshold) <= poincareEpsilon else { return nil }
            return (u, v)
        }
    }

    /// Axis labels for the 2D Poincaré projection axes
    var poincareAxisLabels: (String, String) {
        switch sliceAxis {
        case .x: return ("Y", "Z")
        case .y: return ("X", "Z")
        case .z: return ("X", "Y")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phase Space Trajectory")
                        .font(.headline)
                    if let source = dataSource {
                        Text(source)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.coastalWater.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Mode toggle
                Button(action: {
                    withAnimation {
                        showAllBands.toggle()
                    }
                }) {
                    Text(showAllBands ? "All Bands" : "Band \(selectedBand + 1)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.coastalWater.opacity(0.2))
                        .cornerRadius(CoastalCorners.tight)
                }

                // Axes toggle
                Button(action: {
                    withAnimation {
                        showAxes.toggle()
                    }
                }) {
                    Image(systemName: showAxes ? "line.3.crossed.swirl.circle.fill" : "line.3.crossed.swirl.circle")
                        .foregroundColor(showAxes ? .coastalPrimary : .secondary)
                }

                // Trail toggle
                Button(action: {
                    withAnimation {
                        showTrail.toggle()
                    }
                }) {
                    Image(systemName: showTrail ? "line.diagonal.arrow" : "circle")
                        .foregroundColor(showTrail ? .coastalPrimary : .secondary)
                }

                // Reset view
                Button(action: {
                    withAnimation {
                        rotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                        scale = 1.0
                        animationProgress = 1.0
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .padding()

            // Main 3D view
            RealityView { content in
                // Create trajectory entity
                if let trajectoryEntity = createTrajectoryEntity(
                    points: visiblePoints,
                    showTrail: showTrail
                ) {
                    content.add(trajectoryEntity)
                }

                // Add coordinate axes
                if showAxes {
                    if let axesEntity = createAxesEntity() {
                        content.add(axesEntity)
                    }
                }

                // Add lighting
                let light = DirectionalLight()
                light.light.intensity = 1000
                light.position = [2, 2, 2]
                light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
                content.add(light)

                let ambient = PointLight()
                ambient.light.intensity = 500
                ambient.position = [0, 0, 0]
                content.add(ambient)

            } update: { content in
                // Update rotation and scale
                content.entities.forEach { entity in
                    if entity.name == "axes" {
                        entity.isEnabled = showAxes
                    }

                    if entity.name == "trajectory" {
                        entity.transform.rotation = rotation
                        entity.transform.scale = [scale, scale, scale]
                    }
                }

                // Recreate trajectory with updated points
                content.entities.removeAll { $0.name == "trajectory" }
                if let trajectoryEntity = createTrajectoryEntity(
                    points: visiblePoints,
                    showTrail: showTrail
                ) {
                    trajectoryEntity.transform.rotation = rotation
                    trajectoryEntity.transform.scale = [scale, scale, scale]
                    content.add(trajectoryEntity)
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
                        gestureRecorder?.record(.dragRotate, metadata: [
                            "view": "phaseSpace",
                            "experiment": experimentName,
                            "dx": String(format: "%.1f", value.translation.width),
                            "dy": String(format: "%.1f", value.translation.height)
                        ])
                        // SO(3) snapshot — full quaternion for restriction map
                        let q = rotation
                        gestureRecorder?.record(.so3Rotate, metadata: [
                            "view": "phaseSpace",
                            "experiment": experimentName,
                            "qx": String(format: "%.5f", q.imag.x),
                            "qy": String(format: "%.5f", q.imag.y),
                            "qz": String(format: "%.5f", q.imag.z),
                            "qw": String(format: "%.5f", q.real)
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
                            "view": "phaseSpace",
                            "experiment": experimentName,
                            "scale": String(format: "%.2f", Float(value))
                        ])
                    }
            )

            // Slicing controls
            VStack(spacing: 8) {
                HStack {
                    Toggle("Slice Plane", isOn: $sliceEnabled)
                        .toggleStyle(.switch)
                        .font(.caption)
                        .onChange(of: sliceEnabled) { _, enabled in
                            let axisLabel = sliceAxis.rawValue
                            let eventType: GestureEventType = enabled ? (axisLabel == "X" ? .sliceX : axisLabel == "Y" ? .sliceY : .sliceZ) : .viewReset
                            gestureRecorder?.record(eventType, metadata: [
                                "view": "phaseSpace",
                                "axis": axisLabel,
                                "threshold": String(format: "%.2f", sliceThreshold),
                                "enabled": "\(enabled)"
                            ])
                        }
                    Spacer()
                    if sliceEnabled {
                        Picker("Axis", selection: $sliceAxis) {
                            ForEach(SliceAxis.allCases, id: \.self) { axis in
                                Text(axis.rawValue).tag(axis)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                        .font(.caption)
                    }
                }

                if sliceEnabled {
                    HStack {
                        Text("Threshold (\(sliceAxis.rawValue))")
                            .font(.caption2).foregroundStyle(.secondary)
                        Slider(value: $sliceThreshold, in: -1.0...1.0, step: 0.05)
                            .onChange(of: sliceThreshold) { _, _ in
                                // Record Poincaré section event when threshold changes
                                if showPoincareSection {
                                    gestureRecorder?.record(.poincareSection, metadata: [
                                        "view": "phaseSpace",
                                        "axis": sliceAxis.rawValue,
                                        "threshold": String(format: "%.2f", sliceThreshold),
                                        "sectionPoints": "\(poincarePoints.count)"
                                    ])
                                }
                            }
                        Text(String(format: "%.2f", sliceThreshold))
                            .font(.caption2).frame(width: 40)
                    }

                    // Poincaré section toggle
                    HStack {
                        Toggle("Poincaré Section", isOn: $showPoincareSection)
                            .toggleStyle(.switch)
                            .font(.caption)
                        Spacer()
                        if showPoincareSection {
                            Text("\(poincarePoints.count) pts")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Poincaré section 2D panel
                    if showPoincareSection {
                        PoincareSectionView(
                            points: poincarePoints,
                            axisLabels: poincareAxisLabels
                        )
                        .frame(height: 160)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Animation controls
            VStack(spacing: 12) {
                if showAllBands {
                    // Animation scrubber
                    HStack {
                        Button(action: {
                            isAnimating.toggle()
                            if isAnimating {
                                startAnimation()
                            }
                        }) {
                            Image(systemName: isAnimating ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.coastalPrimary)
                        }

                        Slider(value: $animationProgress, in: 0...1)
                            .disabled(isAnimating)

                        Text("\(Int(animationProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 45)
                    }
                } else {
                    // Band selector
                    HStack {
                        Text("Band:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(selectedBand) },
                                set: { selectedBand = Int($0) }
                            ),
                            in: 0...Double(max(numberOfBands - 1, 0)),
                            step: 1
                        )

                        Text("\(selectedBand + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 30)
                    }
                }

                // Info
                HStack(spacing: 20) {
                    InfoBadge(
                        label: "Total Points",
                        value: "\(phaseSpace.nPoints)"
                    )

                    InfoBadge(
                        label: showAllBands ? "Showing" : "Band Points",
                        value: "\(visiblePoints.count)"
                    )

                    InfoBadge(
                        label: "Bands",
                        value: "\(numberOfBands)"
                    )
                }
            }
            .padding()
            .background(Color.coastalBackground)

            // Legend
            PhaseSpaceLegend()
                .padding()
        }
        .navigationTitle(experimentName)
    }

    // MARK: - RealityKit Entity Creation

    private func createTrajectoryEntity(points: [SIMD3<Float>], showTrail: Bool) -> Entity? {
        guard !points.isEmpty else { return nil }

        let normalizedPoints = normalizePoints(points)
        let parentEntity = Entity()
        parentEntity.name = "trajectory"

        if showTrail {
            // Create line segments for trail
            for i in 0..<(normalizedPoints.count - 1) {
                let start = normalizedPoints[i]
                let end = normalizedPoints[i + 1]

                let segment = createLineSegment(from: start, to: end, index: i, total: normalizedPoints.count)
                parentEntity.addChild(segment)
            }
        }

        // Add point markers along trajectory
        let markerInterval = max(1, normalizedPoints.count / 50) // Show ~50 markers max
        for (index, point) in normalizedPoints.enumerated() where index % markerInterval == 0 {
            let marker = createPointMarker(
                at: point,
                index: index,
                total: normalizedPoints.count,
                size: 0.015
            )
            parentEntity.addChild(marker)
        }

        // Add start marker (sea grass green)
        if let first = normalizedPoints.first {
            let startMarker = createSpecialMarker(at: first, color: UIColor(Color.seaGrass), size: 0.04)
            parentEntity.addChild(startMarker)
        }

        // Add end marker (pink thistle)
        if let last = normalizedPoints.last {
            let endMarker = createSpecialMarker(at: last, color: UIColor(Color.pinkThistle), size: 0.04)
            parentEntity.addChild(endMarker)
        }

        return parentEntity
    }

    private func createLineSegment(from start: SIMD3<Float>, to end: SIMD3<Float>, index: Int, total: Int) -> ModelEntity {
        let midpoint = (start + end) / 2
        let direction = end - start
        let length = simd_length(direction)

        // Color gradient along trajectory
        let ratio = Float(index) / Float(max(total - 1, 1))
        let color = colorForProgress(ratio)

        var material = UnlitMaterial()
        material.color = .init(tint: color.withAlphaComponent(0.6))

        let cylinder = ModelEntity(
            mesh: .generateBox(size: [0.003, length, 0.003]),
            materials: [material]
        )

        cylinder.position = midpoint

        // Rotate to align with segment direction
        if length > 0.001 {
            let up = SIMD3<Float>(0, 1, 0)
            let normalizedDir = simd_normalize(direction)
            let rotation = simd_quatf(from: up, to: normalizedDir)
            cylinder.transform.rotation = rotation
        }

        return cylinder
    }

    private func createPointMarker(at position: SIMD3<Float>, index: Int, total: Int, size: Float) -> ModelEntity {
        let ratio = Float(index) / Float(max(total - 1, 1))
        let color = colorForProgress(ratio)

        var material = UnlitMaterial()
        material.color = .init(tint: color)

        let sphere = ModelEntity(
            mesh: .generateSphere(radius: size),
            materials: [material]
        )
        sphere.position = position

        return sphere
    }

    private func createSpecialMarker(at position: SIMD3<Float>, color: UIColor, size: Float) -> ModelEntity {
        var material = UnlitMaterial()
        material.color = .init(tint: color)

        let sphere = ModelEntity(
            mesh: .generateSphere(radius: size),
            materials: [material]
        )
        sphere.position = position

        // Add glow effect with larger transparent sphere
        var glowMaterial = UnlitMaterial()
        glowMaterial.color = .init(tint: color.withAlphaComponent(0.3))

        let glow = ModelEntity(
            mesh: .generateSphere(radius: size * 1.5),
            materials: [glowMaterial]
        )
        sphere.addChild(glow)

        return sphere
    }

    private func createAxesEntity() -> Entity? {
        let axesEntity = Entity()
        axesEntity.name = "axes"

        let axisLength: Float = 0.8
        let axisRadius: Float = 0.005

        // X axis (red)
        var xMaterial = UnlitMaterial()
        xMaterial.color = .init(tint: UIColor.red.withAlphaComponent(0.5))
        let xAxis = ModelEntity(
            mesh: .generateBox(size: [axisLength, axisRadius, axisRadius]),
            materials: [xMaterial]
        )
        xAxis.position = [axisLength / 2, 0, 0]
        axesEntity.addChild(xAxis)

        // Y axis (green)
        var yMaterial = UnlitMaterial()
        yMaterial.color = .init(tint: UIColor.green.withAlphaComponent(0.5))
        let yAxis = ModelEntity(
            mesh: .generateBox(size: [axisRadius, axisLength, axisRadius]),
            materials: [yMaterial]
        )
        yAxis.position = [0, axisLength / 2, 0]
        axesEntity.addChild(yAxis)

        // Z axis (blue)
        var zMaterial = UnlitMaterial()
        zMaterial.color = .init(tint: UIColor.blue.withAlphaComponent(0.5))
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

        return points.map { point in
            (point - center) * scale
        }
    }

    private func colorForProgress(_ ratio: Float) -> UIColor {
        // Coastal current-flow gradient: deep ocean → coastal water → sea grass → sunset coral → sunset orange → pink thistle
        if ratio < 0.2 {
            // Deep ocean to coastal water
            let t = ratio / 0.2
            return UIColor.interpolate(from: UIColor(Color.deepOcean), to: UIColor(Color.coastalWater), progress: CGFloat(t))
        } else if ratio < 0.4 {
            // Coastal water to sea grass
            let t = (ratio - 0.2) / 0.2
            return UIColor.interpolate(from: UIColor(Color.coastalWater), to: UIColor(Color.seaGrass), progress: CGFloat(t))
        } else if ratio < 0.6 {
            // Sea grass to sunset coral
            let t = (ratio - 0.4) / 0.2
            return UIColor.interpolate(from: UIColor(Color.seaGrass), to: UIColor(Color.sunsetCoral), progress: CGFloat(t))
        } else if ratio < 0.8 {
            // Sunset coral to sunset orange
            let t = (ratio - 0.6) / 0.2
            return UIColor.interpolate(from: UIColor(Color.sunsetCoral), to: UIColor(Color.sunsetOrange), progress: CGFloat(t))
        } else {
            // Sunset orange to pink thistle
            let t = (ratio - 0.8) / 0.2
            return UIColor.interpolate(from: UIColor(Color.sunsetOrange), to: UIColor(Color.pinkThistle), progress: CGFloat(t))
        }
    }

    private func startAnimation() {
        animationProgress = 0

        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if !isAnimating {
                timer.invalidate()
                return
            }

            animationProgress += 0.01

            if animationProgress >= 1.0 {
                animationProgress = 0 // Loop
            }
        }
    }
}

// MARK: - Info Badge

struct InfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Phase Space Legend

struct PhaseSpaceLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.seaGrass)
                        .frame(width: 12, height: 12)
                    Text("Start")
                        .font(.caption2)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.pinkThistle)
                        .frame(width: 12, height: 12)
                    Text("End")
                        .font(.caption2)
                }

                HStack(spacing: 6) {
                    Rectangle()
                        .fill(CoastalGradients.currentFlow)
                        .frame(width: 60, height: 8)
                        .cornerRadius(4)
                    Text("Current Flow")
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.tight)
    }
}

// MARK: - Preview

#Preview {
    // Sample spiral trajectory
    let samplePoints: [[Double]] = (0..<200).map { i in
        let t = Double(i) / 200.0 * 4 * .pi
        let r = 0.5 + Double(i) / 400.0
        return [
            r * cos(t),
            Double(i) / 100.0 - 1.0,
            r * sin(t)
        ]
    }

    let samplePhaseSpace = VisualizationData(
        points: samplePoints,
        nPoints: 200,
        dimensions: 3,
        description: "Sample phase space trajectory"
    )

    NavigationStack {
        PhaseSpaceTrajectoryView(
            phaseSpace: samplePhaseSpace,
            experimentName: "Test Experiment"
        )
    }
}
