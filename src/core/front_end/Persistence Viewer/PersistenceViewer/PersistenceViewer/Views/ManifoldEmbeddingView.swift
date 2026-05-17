//
//  ManifoldEmbeddingView.swift
//  PersistenceViewer
//
//  Manifold embedding visualization with Isomap, LLE, and Diffusion Maps
//  Shows dimensionality reduction results with label-based coloring
//

import SwiftUI
import RealityKit

enum ManifoldType: String, CaseIterable {
    case isomap = "Isomap"
    case lle = "LLE"
    case diffusionMap = "Diffusion Map"
}

struct ManifoldEmbeddingView: View {
    let manifolds: ManifoldEmbeddings
    let labels: LabelData?
    let experimentName: String

    @State private var selectedManifold: ManifoldType = .isomap
    @State private var rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    @State private var scale: Float = 1.0
    @State private var showAxes: Bool = true
    @State private var showLabels: Bool = true
    @State private var comparisonMode: Bool = false
    @State private var comparisonManifold: ManifoldType = .lle
    @State private var pointSize: Float = 0.02

    var availableManifolds: [ManifoldType] {
        var available: [ManifoldType] = []
        if manifolds.isomap != nil { available.append(.isomap) }
        if manifolds.lle != nil { available.append(.lle) }
        if manifolds.diffusionMap != nil { available.append(.diffusionMap) }
        return available
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("Manifold Embeddings")
                    .font(.headline)

                Spacer()

                // Comparison mode toggle
                Button(action: {
                    withAnimation {
                        comparisonMode.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: comparisonMode ? "square.split.2x1.fill" : "square.split.2x1")
                        Text(comparisonMode ? "Split" : "Single")
                            .font(.caption)
                    }
                    .foregroundColor(comparisonMode ? .coastalPrimary : .secondary)
                }

                // Label coloring toggle
                if labels != nil {
                    Button(action: {
                        withAnimation {
                            showLabels.toggle()
                        }
                    }) {
                        Image(systemName: showLabels ? "paintpalette.fill" : "paintpalette")
                            .foregroundColor(showLabels ? .coastalAccent : .secondary)
                    }
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

                // Reset
                Button(action: {
                    withAnimation {
                        rotation = simd_quatf(angle: 0, axis: [0, 1, 0])
                        scale = 1.0
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .padding()

            // Manifold type selector
            if !comparisonMode {
                Picker("Manifold Type", selection: $selectedManifold) {
                    ForEach(availableManifolds, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            } else {
                HStack {
                    // Primary manifold picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("Primary", selection: $selectedManifold) {
                            ForEach(availableManifolds, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Spacer()

                    Image(systemName: "arrow.left.and.right")
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Comparison manifold picker
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("Comparison", selection: $comparisonManifold) {
                            ForEach(availableManifolds, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.horizontal)
            }

            // Main visualization
            if comparisonMode {
                // Side-by-side comparison
                HStack(spacing: 0) {
                    // Left manifold
                    ManifoldVisualizationPane(
                        data: getManifoldData(selectedManifold),
                        labels: labels,
                        showLabels: showLabels,
                        showAxes: showAxes,
                        rotation: $rotation,
                        scale: $scale,
                        pointSize: pointSize,
                        title: selectedManifold.rawValue
                    )

                    Divider()

                    // Right manifold
                    ManifoldVisualizationPane(
                        data: getManifoldData(comparisonManifold),
                        labels: labels,
                        showLabels: showLabels,
                        showAxes: showAxes,
                        rotation: $rotation,
                        scale: $scale,
                        pointSize: pointSize,
                        title: comparisonManifold.rawValue
                    )
                }
            } else {
                // Single manifold view
                ManifoldVisualizationPane(
                    data: getManifoldData(selectedManifold),
                    labels: labels,
                    showLabels: showLabels,
                    showAxes: showAxes,
                    rotation: $rotation,
                    scale: $scale,
                    pointSize: pointSize,
                    title: nil
                )
            }

            // Controls panel
            VStack(spacing: 12) {
                // Point size control
                HStack {
                    Text("Point Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $pointSize, in: 0.01...0.04, step: 0.005)
                    Text(String(format: "%.3f", pointSize))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }

                // Info
                if let data = getManifoldData(selectedManifold) {
                    HStack(spacing: 20) {
                        InfoBadge(label: "Points", value: "\(data.nPoints)")
                        InfoBadge(label: "Dimensions", value: "\(data.dimensions)D")
                        if let labels = labels {
                            InfoBadge(label: "Configs", value: "\(Set(labels.flatLabels).count)")
                        }
                    }
                }
            }
            .padding()
            .background(Color.coastalBackground)

            // Legend
            if showLabels, let labels = labels {
                ManifoldLegend(labels: labels)
                    .padding()
            }
        }
        .navigationTitle(experimentName)
    }

    private func getManifoldData(_ type: ManifoldType) -> VisualizationData? {
        switch type {
        case .isomap:
            return manifolds.isomap
        case .lle:
            return manifolds.lle
        case .diffusionMap:
            return manifolds.diffusionMap
        }
    }
}

// MARK: - Manifold Visualization Pane

struct ManifoldVisualizationPane: View {
    let data: VisualizationData?
    let labels: LabelData?
    let showLabels: Bool
    let showAxes: Bool
    @Binding var rotation: simd_quatf
    @Binding var scale: Float
    let pointSize: Float
    let title: String?

    var body: some View {
        VStack(spacing: 0) {
            // Title for comparison mode
            if let title = title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.9))
            }

            // 3D visualization
            RealityView { content in
                guard let data = data else { return }

                // Create point cloud with labels
                if let entity = createManifoldEntity(
                    data: data,
                    labels: labels,
                    showLabels: showLabels,
                    pointSize: pointSize
                ) {
                    content.add(entity)
                }

                // Add axes
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

            } update: { content in
                // Update axes visibility
                content.entities.forEach { entity in
                    if entity.name == "axes" {
                        entity.isEnabled = showAxes
                    }

                    // Apply rotation and scale
                    if entity.name == "manifold" {
                        entity.transform.rotation = rotation
                        entity.transform.scale = [scale, scale, scale]
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Convert 2D drag to 3D rotation
                        let sensitivity: Float = 0.01
                        let deltaX = Float(value.translation.width) * sensitivity
                        let deltaY = Float(value.translation.height) * sensitivity

                        // Create rotation quaternions for each axis
                        let yawRotation = simd_quatf(angle: -deltaX, axis: [0, 1, 0])  // Left/right → rotate around Y
                        let pitchRotation = simd_quatf(angle: deltaY, axis: [1, 0, 0]) // Up/down → rotate around X

                        // Combine rotations (order matters!)
                        let deltaRotation = yawRotation * pitchRotation

                        // Apply to current rotation
                        rotation = deltaRotation * rotation
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = Float(value)
                    }
            )
            .background(Color.black.opacity(0.02))
        }
    }

    // MARK: - Entity Creation

    private func createManifoldEntity(
        data: VisualizationData,
        labels: LabelData?,
        showLabels: Bool,
        pointSize: Float
    ) -> ModelEntity? {
        let points = data.simd3Points
        guard !points.isEmpty else { return nil }

        let normalizedPoints = normalizePoints(points)
        let parentEntity = Entity()
        parentEntity.name = "manifold"

        let flatLabels = labels?.flatLabels ?? []

        // Create spheres for each point
        for (index, point) in normalizedPoints.enumerated() {
            let label = index < flatLabels.count ? flatLabels[index] : 0
            let color = showLabels ? colorForLabel(label) : .blue

            var material = UnlitMaterial()
            material.color = .init(tint: color.withAlphaComponent(0.8))

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

        let axisLength: Float = 0.8
        let axisRadius: Float = 0.005

        // X axis (red)
        var xMaterial = UnlitMaterial()
        xMaterial.color = .init(tint: UIColor.red.withAlphaComponent(0.6))
        let xAxis = ModelEntity(
            mesh: .generateBox(size: [axisLength, axisRadius, axisRadius]),
            materials: [xMaterial]
        )
        xAxis.position = [axisLength / 2, 0, 0]
        axesEntity.addChild(xAxis)

        // Y axis (green)
        var yMaterial = UnlitMaterial()
        yMaterial.color = .init(tint: UIColor.green.withAlphaComponent(0.6))
        let yAxis = ModelEntity(
            mesh: .generateBox(size: [axisRadius, axisLength, axisRadius]),
            materials: [yMaterial]
        )
        yAxis.position = [0, axisLength / 2, 0]
        axesEntity.addChild(yAxis)

        // Z axis (blue)
        var zMaterial = UnlitMaterial()
        zMaterial.color = .init(tint: UIColor.blue.withAlphaComponent(0.6))
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

    private func colorForLabel(_ label: Int) -> UIColor {
        // Coastal colors for different scatterer configurations
        return UIColor(Color.coastalLabel(label))
    }
}

// MARK: - Manifold Legend

struct ManifoldLegend: View {
    let labels: LabelData

    private var configCounts: [(label: Int, count: Int)] {
        let flatLabels = labels.flatLabels
        let uniqueLabels = Set(flatLabels).sorted()

        return uniqueLabels.map { label in
            let count = flatLabels.filter { $0 == label }.count
            return (label, count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Configuration Labels")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(configCounts, id: \.label) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForLabel(item.label))
                                .frame(width: 12, height: 12)
                            Text("Config \(item.label + 1)")
                                .font(.caption2)
                            Text("(\(item.count))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.tight)
    }

    private func colorForLabel(_ label: Int) -> Color {
        return .coastalLabel(label)
    }
}

// MARK: - Preview

#Preview {
    // Sample manifold data
    let samplePoints: [[Double]] = (0..<300).map { i in
        let theta = Double(i) / 300.0 * 2 * .pi
        let phi = Double(i) / 150.0 * .pi
        return [
            sin(phi) * cos(theta),
            sin(phi) * sin(theta),
            cos(phi)
        ]
    }

    let sampleIsomap = VisualizationData(
        points: samplePoints,
        nPoints: 300,
        dimensions: 3,
        description: "Sample Isomap embedding"
    )

    let sampleLLE = VisualizationData(
        points: samplePoints.map { [$0[0] * 0.8, $0[1] * 1.2, $0[2] * 0.9] },
        nPoints: 300,
        dimensions: 3,
        description: "Sample LLE embedding"
    )

    let sampleManifolds = ManifoldEmbeddings(
        isomap: sampleIsomap,
        diffusionMap: nil,
        lle: sampleLLE
    )

    let sampleLabels = LabelData(
        labels: (0..<300).map { Double($0 / 75) },
        nLabels: 300,
        description: "Sample labels"
    )

    NavigationStack {
        ManifoldEmbeddingView(
            manifolds: sampleManifolds,
            labels: sampleLabels,
            experimentName: "Test Experiment"
        )
    }
}
