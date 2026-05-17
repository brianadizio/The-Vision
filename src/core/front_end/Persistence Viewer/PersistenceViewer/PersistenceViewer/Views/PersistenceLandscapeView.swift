//
//  PersistenceLandscapeView.swift
//  PersistenceViewer
//
//  Persistence landscape visualization
//  Shows multi-layer landscape functions derived from persistence diagrams
//

import SwiftUI
import RealityKit

enum LandscapeViewMode {
    case flat2D
    case surface3D
}

struct PersistenceLandscapeView: View {
    let landscape: PersistenceLandscapeData
    let bandName: String

    @State private var viewMode: LandscapeViewMode = .flat2D
    @State private var selectedLayers: Set<Int> = [0, 1, 2]
    @State private var selectedThresholdIndex: Int? = nil
    @State private var showFilled: Bool = true
    @State private var rotationAngle: Float = 0
    @State private var scale: Float = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("Persistence Landscape")
                    .font(.headline)

                Spacer()

                // View mode toggle
                Button(action: {
                    withAnimation {
                        viewMode = viewMode == .flat2D ? .surface3D : .flat2D
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewMode == .flat2D ? "chart.xyaxis.line" : "view.3d")
                        Text(viewMode == .flat2D ? "2D" : "3D")
                            .font(.caption)
                    }
                    .foregroundColor(.coastalPrimary)
                }

                // Fill toggle (for 2D mode)
                if viewMode == .flat2D {
                    Button(action: {
                        withAnimation {
                            showFilled.toggle()
                        }
                    }) {
                        Image(systemName: showFilled ? "chart.bar.fill" : "chart.bar")
                            .foregroundColor(showFilled ? .coastalPrimary : .secondary)
                    }
                }

                // Reset (for 3D mode)
                if viewMode == .surface3D {
                    Button(action: {
                        withAnimation {
                            rotationAngle = 0
                            scale = 1.0
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
            .padding()

            // Layer selector
            LayerSelector(
                numberOfLayers: landscape.numberOfLayers,
                selectedLayers: $selectedLayers
            )
            .padding(.horizontal)

            // Main visualization
            if viewMode == .flat2D {
                // 2D landscape chart
                GeometryReader { geometry in
                    LandscapeChart2D(
                        landscape: landscape,
                        selectedLayers: selectedLayers,
                        selectedThresholdIndex: $selectedThresholdIndex,
                        showFilled: showFilled,
                        size: geometry.size
                    )
                }
                .background(Color.coastalBackground)
                .cornerRadius(CoastalCorners.standard)
                .padding(.horizontal)

                // Threshold detail
                if let index = selectedThresholdIndex {
                    ThresholdLandscapeCard(
                        landscape: landscape,
                        thresholdIndex: index,
                        selectedLayers: selectedLayers
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                // 3D surface view
                Landscape3DSurface(
                    landscape: landscape,
                    selectedLayers: selectedLayers,
                    rotationAngle: $rotationAngle,
                    scale: $scale
                )
                .background(Color.black.opacity(0.02))
            }

            // Info panel
            LandscapeInfoPanel(
                landscape: landscape,
                selectedLayers: selectedLayers
            )
            .padding()
        }
        .navigationTitle(bandName)
    }
}

// MARK: - Layer Selector

struct LayerSelector: View {
    let numberOfLayers: Int
    @Binding var selectedLayers: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Layers")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Select all / none
                Button(action: {
                    if selectedLayers.count == numberOfLayers {
                        selectedLayers.removeAll()
                    } else {
                        selectedLayers = Set(0..<numberOfLayers)
                    }
                }) {
                    Text(selectedLayers.count == numberOfLayers ? "Clear" : "All")
                        .font(.caption2)
                        .foregroundColor(.coastalPrimary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<numberOfLayers, id: \.self) { layer in
                        LayerToggleButton(
                            layer: layer,
                            isSelected: selectedLayers.contains(layer),
                            color: colorForLayer(layer)
                        ) {
                            if selectedLayers.contains(layer) {
                                selectedLayers.remove(layer)
                            } else {
                                selectedLayers.insert(layer)
                            }
                        }
                    }
                }
            }
        }
    }

    private func colorForLayer(_ layer: Int) -> Color {
        // Coastal landscape layers: ocean depths to coastal vegetation
        let colors: [Color] = [.deepOcean, .coastalWater, .seaGrass, .sunsetCoral, .pinkThistle]
        return colors[layer % colors.count]
    }
}

struct LayerToggleButton: View {
    let layer: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("λ\(layer + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// MARK: - 2D Landscape Chart

struct LandscapeChart2D: View {
    let landscape: PersistenceLandscapeData
    let selectedLayers: Set<Int>
    @Binding var selectedThresholdIndex: Int?
    let showFilled: Bool
    let size: CGSize

    private var maxValue: Double {
        let selectedValues = landscape.values.enumerated().compactMap { index, layer -> [Double]? in
            selectedLayers.contains(index) ? layer : nil
        }.flatMap { $0 }

        return selectedValues.max() ?? 1.0
    }

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 50
            let plotWidth = size.width - 2 * padding
            let plotHeight = size.height - 2 * padding

            // Helper to convert data to screen coordinates
            func toScreen(bin: Int, value: Double) -> CGPoint {
                let x = padding + CGFloat(bin) / CGFloat(max(landscape.numberOfBins - 1, 1)) * plotWidth
                let y = size.height - padding - CGFloat(value / maxValue) * plotHeight
                return CGPoint(x: x, y: y)
            }

            // Draw axes
            let axisPath = Path { path in
                path.move(to: CGPoint(x: padding, y: size.height - padding))
                path.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))
                path.move(to: CGPoint(x: padding, y: padding))
                path.addLine(to: CGPoint(x: padding, y: size.height - padding))
            }
            context.stroke(axisPath, with: .color(.gray), lineWidth: 2)

            // Draw grid
            for i in 0...5 {
                let value = maxValue * Double(i) / 5.0
                let y = size.height - padding - CGFloat(value / maxValue) * plotHeight

                let gridPath = Path { path in
                    path.move(to: CGPoint(x: padding, y: y))
                    path.addLine(to: CGPoint(x: size.width - padding, y: y))
                }
                context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

                // Y-axis label
                var yLabelContext = context
                yLabelContext.translateBy(x: padding - 30, y: y)
                yLabelContext.draw(Text(String(format: "%.1f", value)).font(.caption2), at: .zero)
            }

            // Draw landscape layers
            for layer in selectedLayers.sorted() {
                guard layer < landscape.numberOfLayers else { continue }
                let values = landscape.values[layer]

                let color = colorForLayer(layer)

                // Draw filled area
                if showFilled {
                    let fillPath = Path { path in
                        let startPoint = toScreen(bin: 0, value: values[0])
                        path.move(to: CGPoint(x: startPoint.x, y: size.height - padding))
                        path.addLine(to: startPoint)

                        for (bin, value) in values.enumerated() {
                            let point = toScreen(bin: bin, value: value)
                            path.addLine(to: point)
                        }

                        let endPoint = toScreen(bin: values.count - 1, value: values.last!)
                        path.addLine(to: CGPoint(x: endPoint.x, y: size.height - padding))
                        path.closeSubpath()
                    }
                    context.fill(fillPath, with: .color(color.opacity(0.15)))
                }

                // Draw line
                let linePath = Path { path in
                    if let firstValue = values.first {
                        let startPoint = toScreen(bin: 0, value: firstValue)
                        path.move(to: startPoint)

                        for (bin, value) in values.enumerated() {
                            let point = toScreen(bin: bin, value: value)
                            path.addLine(to: point)
                        }
                    }
                }
                context.stroke(linePath, with: .color(color), lineWidth: 2)
            }

            // Draw selected threshold
            if let index = selectedThresholdIndex, index < landscape.numberOfBins {
                let x = padding + CGFloat(index) / CGFloat(max(landscape.numberOfBins - 1, 1)) * plotWidth

                let selectionPath = Path { path in
                    path.move(to: CGPoint(x: x, y: padding))
                    path.addLine(to: CGPoint(x: x, y: size.height - padding))
                }
                context.stroke(
                    selectionPath,
                    with: .color(.sunsetOrange),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                )

                // Draw points at intersections
                for layer in selectedLayers.sorted() {
                    guard layer < landscape.numberOfLayers else { continue }
                    let values = landscape.values[layer]
                    guard index < values.count else { continue }

                    let point = toScreen(bin: index, value: values[index])
                    let circle = Path { path in
                        path.addEllipse(in: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
                    }
                    context.fill(circle, with: .color(colorForLayer(layer)))
                    context.stroke(circle, with: .color(.white), lineWidth: 2)
                }
            }

            // Draw axis labels
            var xLabelContext = context
            xLabelContext.translateBy(x: size.width / 2, y: size.height - 10)
            xLabelContext.draw(Text("Threshold").font(.caption), at: .zero)

            var yLabelContext = context
            yLabelContext.translateBy(x: 15, y: size.height / 2)
            yLabelContext.rotate(by: .degrees(-90))
            yLabelContext.draw(Text("Landscape Value").font(.caption), at: .zero)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleTap(at: value.location)
                }
        )
    }

    private func handleTap(at location: CGPoint) {
        let padding: CGFloat = 50
        let plotWidth = size.width - 2 * padding

        let relativeX = location.x - padding
        guard relativeX >= 0 && relativeX <= plotWidth else {
            selectedThresholdIndex = nil
            return
        }

        let binIndex = Int((relativeX / plotWidth) * CGFloat(landscape.numberOfBins))
        selectedThresholdIndex = min(max(binIndex, 0), landscape.numberOfBins - 1)
    }

    private func colorForLayer(_ layer: Int) -> Color {
        // Coastal landscape layers: ocean depths to coastal vegetation
        let colors: [Color] = [.deepOcean, .coastalWater, .seaGrass, .sunsetCoral, .pinkThistle]
        return colors[layer % colors.count]
    }
}

// MARK: - 3D Landscape Surface

struct Landscape3DSurface: View {
    let landscape: PersistenceLandscapeData
    let selectedLayers: Set<Int>
    @Binding var rotationAngle: Float
    @Binding var scale: Float

    var body: some View {
        RealityView { content in
            // Create 3D surface for each selected layer
            for layer in selectedLayers.sorted() {
                guard layer < landscape.numberOfLayers else { continue }

                if let surfaceEntity = create3DSurface(
                    values: landscape.values[layer],
                    layer: layer,
                    color: colorForLayer(layer)
                ) {
                    content.add(surfaceEntity)
                }
            }

            // Add axes
            if let axesEntity = createAxesEntity() {
                content.add(axesEntity)
            }

            // Add lighting
            let light = DirectionalLight()
            light.light.intensity = 1000
            light.position = [2, 2, 2]
            light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
            content.add(light)

        } update: { content in
            content.entities.forEach { entity in
                if entity.name.starts(with: "landscape") {
                    entity.transform.rotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                    entity.transform.scale = [scale, scale, scale]
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    rotationAngle += Float(value.translation.width) * 0.01
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = Float(value)
                }
        )
    }

    private func create3DSurface(values: [Double], layer: Int, color: Color) -> Entity? {
        guard !values.isEmpty else { return nil }

        let parentEntity = Entity()
        parentEntity.name = "landscape_\(layer)"

        let maxValue = values.max() ?? 1.0
        let layerOffset = Float(layer) * 0.15 // Stack layers

        // Create mesh from landscape values
        for i in 0..<(values.count - 1) {
            let x1 = Float(i) / Float(values.count - 1) - 0.5
            let x2 = Float(i + 1) / Float(values.count - 1) - 0.5
            let y1 = Float(values[i] / maxValue) * 0.5
            let y2 = Float(values[i + 1] / maxValue) * 0.5

            // Create vertical posts
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor(color).withAlphaComponent(0.6))

            let height = max(y1, 0.01)
            let post = ModelEntity(
                mesh: .generateBox(size: [0.005, height, 0.01]),
                materials: [material]
            )
            post.position = [x1, height / 2 + layerOffset, 0]
            parentEntity.addChild(post)
        }

        return parentEntity
    }

    private func createAxesEntity() -> Entity? {
        let axesEntity = Entity()
        axesEntity.name = "axes"

        let axisLength: Float = 0.6
        let axisRadius: Float = 0.003

        // X axis (red)
        var xMaterial = UnlitMaterial()
        xMaterial.color = .init(tint: UIColor.red.withAlphaComponent(0.5))
        let xAxis = ModelEntity(
            mesh: .generateBox(size: [axisLength, axisRadius, axisRadius]),
            materials: [xMaterial]
        )
        xAxis.position = [0, 0, 0]
        axesEntity.addChild(xAxis)

        return axesEntity
    }

    private func colorForLayer(_ layer: Int) -> Color {
        // Coastal landscape layers: ocean depths to coastal vegetation
        let colors: [Color] = [.deepOcean, .coastalWater, .seaGrass, .sunsetCoral, .pinkThistle]
        return colors[layer % colors.count]
    }
}

// MARK: - Threshold Landscape Card

struct ThresholdLandscapeCard: View {
    let landscape: PersistenceLandscapeData
    let thresholdIndex: Int
    let selectedLayers: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Threshold \(thresholdIndex)")
                    .font(.headline)
                Spacer()
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                ForEach(selectedLayers.sorted(), id: \.self) { layer in
                    if layer < landscape.numberOfLayers,
                       thresholdIndex < landscape.values[layer].count {
                        GridRow {
                            Circle()
                                .fill(colorForLayer(layer))
                                .frame(width: 10, height: 10)
                            Text("λ\(layer + 1):")
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.3f", landscape.values[layer][thresholdIndex]))
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.sunsetOrange.opacity(0.1))
        .cornerRadius(CoastalCorners.standard)
    }

    private func colorForLayer(_ layer: Int) -> Color {
        // Coastal landscape layers: ocean depths to coastal vegetation
        let colors: [Color] = [.deepOcean, .coastalWater, .seaGrass, .sunsetCoral, .pinkThistle]
        return colors[layer % colors.count]
    }
}

// MARK: - Landscape Info Panel

struct LandscapeInfoPanel: View {
    let landscape: PersistenceLandscapeData
    let selectedLayers: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                InfoBadge(label: "Layers", value: "\(landscape.numberOfLayers)")
                InfoBadge(label: "Bins", value: "\(landscape.numberOfBins)")
                InfoBadge(label: "Selected", value: "\(selectedLayers.count)")
            }
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.tight)
    }
}

// MARK: - Preview

#Preview {
    // Sample landscape data (5 layers, 100 bins)
    let sampleValues: [[Double]] = (0..<5).map { layer in
        (0..<100).map { i in
            let t = Double(i) / 100.0
            let amplitude = 1.0 / Double(layer + 1)
            return amplitude * max(0, sin(t * 3.14 * 2) + Double.random(in: -0.1...0.1))
        }
    }

    let sampleLandscape = PersistenceLandscapeData(
        values: sampleValues,
        shape: [5, 100]
    )

    NavigationStack {
        PersistenceLandscapeView(
            landscape: sampleLandscape,
            bandName: "Band 01"
        )
    }
}
