//
//  PersistenceDiagramView.swift
//  PersistenceViewer
//
//  Interactive persistence diagram visualization
//  Birth vs Death scatter plot with color-coded homology dimensions
//

import SwiftUI

struct PersistenceDiagramView: View {
    let features: [PersistenceFeature]
    let bandName: String
    var gestureRecorder: GestureRecorder? = nil  // injected for session tracking

    @State private var selectedFeature: PersistenceFeature?
    @State private var showH0: Bool = true
    @State private var showH1: Bool = true
    @State private var showH2: Bool = true

    // Spread-zoom state
    @State private var zoomScale: CGFloat = 1.0
    @State private var zoomAnchor: UnitPoint = .center
    @State private var annotationText: String = ""
    @State private var showAnnotationInput: Bool = false

    var filteredFeatures: [PersistenceFeature] {
        features.filter { feature in
            switch feature.dimension {
            case 0: return showH0
            case 1: return showH1
            case 2: return showH2
            default: return false
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with filters
            HStack {
                Text("Persistence Diagram")
                    .font(.headline)

                Spacer()

                // Dimension toggles
                HStack(spacing: 16) {
                    DimensionToggle(dimension: 0, isOn: $showH0, color: .h0Color, label: "H₀")
                    DimensionToggle(dimension: 1, isOn: $showH1, color: .h1Color, label: "H₁")
                    DimensionToggle(dimension: 2, isOn: $showH2, color: .h2Color, label: "H₂")
                }
            }
            .padding()

            // Main diagram with spread-zoom
            GeometryReader { geometry in
                PersistenceDiagramCanvas(
                    features: filteredFeatures,
                    selectedFeature: $selectedFeature,
                    size: geometry.size
                )
                .scaleEffect(zoomScale, anchor: zoomAnchor)
                .animation(.spring(response: 0.3), value: zoomScale)
            }
            .background(Color.coastalBackground)
            .cornerRadius(CoastalCorners.standard)
            .padding(.horizontal)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = max(0.5, min(5.0, value))
                    }
                    .onEnded { value in
                        gestureRecorder?.record(.spreadZoom, metadata: [
                            "view": "persistenceDiagram",
                            "band": bandName,
                            "scale": String(format: "%.2f", Double(value))
                        ])
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.spring(response: 0.4)) { zoomScale = 1.0 }
                        gestureRecorder?.record(.viewReset, metadata: ["view": "persistenceDiagram", "band": bandName])
                    }
            )

            // Feature details with annotation support
            if let selected = selectedFeature {
                VStack(spacing: 8) {
                    FeatureDetailCard(feature: selected)

                    // Annotate button
                    if !showAnnotationInput {
                        Button(action: {
                            withAnimation { showAnnotationInput = true }
                            gestureRecorder?.record(.tapAnnotate, metadata: [
                                "view": "persistenceDiagram",
                                "band": bandName,
                                "featureId": "\(selected.id)",
                                "homologyClass": selected.homologyClass
                            ])
                            gestureRecorder?.trackAnnotation()
                        }) {
                            Label("Add Note", systemImage: "square.and.pencil")
                                .font(.caption)
                                .foregroundColor(.coastalPrimary)
                        }
                    } else {
                        HStack {
                            TextField("Annotation for \(selected.homologyClass)…", text: $annotationText)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            Button("Save") {
                                withAnimation { showAnnotationInput = false; annotationText = "" }
                            }
                            .font(.caption)
                            .foregroundColor(.coastalPrimary)
                        }
                    }
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Legend
            PersistenceDiagramLegend(features: features)
                .padding()
        }
        .navigationTitle(bandName)
    }
}

// MARK: - Persistence Diagram Canvas

struct PersistenceDiagramCanvas: View {
    let features: [PersistenceFeature]
    @Binding var selectedFeature: PersistenceFeature?
    let size: CGSize

    // Calculate bounds from data
    private var bounds: (minBirth: Double, maxDeath: Double) {
        let finiteFeatures = features.filter { $0.death != nil && !$0.isInfinite }
        guard !finiteFeatures.isEmpty else { return (0, 1) }

        let births = finiteFeatures.map { $0.birth }
        let deaths = finiteFeatures.compactMap { $0.death }

        let minBirth = births.min() ?? 0
        let maxDeath = deaths.max() ?? 1

        // Add 10% padding
        let range = maxDeath - minBirth
        let padding = range * 0.1

        return (minBirth - padding, maxDeath + padding)
    }

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 40
            let plotWidth = size.width - 2 * padding
            let plotHeight = size.height - 2 * padding

            let (minVal, maxVal) = bounds
            let range = maxVal - minVal

            // Helper to convert data coordinates to screen coordinates
            func toScreen(birth: Double, death: Double) -> CGPoint {
                let x = padding + CGFloat((birth - minVal) / range) * plotWidth
                let y = size.height - padding - CGFloat((death - minVal) / range) * plotHeight
                return CGPoint(x: x, y: y)
            }

            // Draw axes
            let axisPath = Path { path in
                // X axis
                path.move(to: CGPoint(x: padding, y: size.height - padding))
                path.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))

                // Y axis
                path.move(to: CGPoint(x: padding, y: padding))
                path.addLine(to: CGPoint(x: padding, y: size.height - padding))
            }
            context.stroke(axisPath, with: .color(.gray), lineWidth: 2)

            // Draw diagonal reference line (birth = death)
            let diagonalPath = Path { path in
                let start = toScreen(birth: minVal, death: minVal)
                let end = toScreen(birth: maxVal, death: maxVal)
                path.move(to: start)
                path.addLine(to: end)
            }
            context.stroke(diagonalPath, with: .color(.gray.opacity(0.5)),
                          style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

            // Draw grid lines
            let numGridLines = 5
            for i in 0...numGridLines {
                let value = minVal + (maxVal - minVal) * Double(i) / Double(numGridLines)
                let screenPos = toScreen(birth: value, death: minVal)

                // Vertical grid line
                let vPath = Path { path in
                    path.move(to: CGPoint(x: screenPos.x, y: padding))
                    path.addLine(to: CGPoint(x: screenPos.x, y: size.height - padding))
                }
                context.stroke(vPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

                // Horizontal grid line
                let hPath = Path { path in
                    let y = size.height - padding - CGFloat((value - minVal) / range) * plotHeight
                    path.move(to: CGPoint(x: padding, y: y))
                    path.addLine(to: CGPoint(x: size.width - padding, y: y))
                }
                context.stroke(hPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
            }

            // Draw axis labels
            var axisLabelContext = context
            axisLabelContext.translateBy(x: size.width / 2, y: size.height - 10)
            axisLabelContext.draw(Text("Birth Time").font(.caption), at: .zero)

            var yLabelContext = context
            yLabelContext.translateBy(x: 15, y: size.height / 2)
            yLabelContext.rotate(by: .degrees(-90))
            yLabelContext.draw(Text("Death Time").font(.caption), at: .zero)

            // Draw persistence points
            for feature in features {
                guard let death = feature.death, !feature.isInfinite else { continue }

                let point = toScreen(birth: feature.birth, death: death)
                let isSelected = selectedFeature?.id == feature.id

                // Draw point
                let radius: CGFloat = isSelected ? 8 : 5
                let circle = Path { path in
                    path.addEllipse(in: CGRect(
                        x: point.x - radius,
                        y: point.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                }

                context.fill(circle, with: .color(feature.color))

                if isSelected {
                    context.stroke(circle, with: .color(.white), lineWidth: 2)
                }
            }

            // Draw tick labels
            for i in 0...numGridLines {
                let value = minVal + (maxVal - minVal) * Double(i) / Double(numGridLines)
                let label = String(format: "%.2f", value)

                // X-axis tick
                let xPos = padding + CGFloat(Double(i) / Double(numGridLines)) * plotWidth
                var xTickContext = context
                xTickContext.translateBy(x: xPos, y: size.height - padding + 15)
                xTickContext.draw(Text(label).font(.caption2), at: .zero)

                // Y-axis tick
                let yPos = size.height - padding - CGFloat(Double(i) / Double(numGridLines)) * plotHeight
                var yTickContext = context
                yTickContext.translateBy(x: padding - 25, y: yPos)
                yTickContext.draw(Text(label).font(.caption2), at: .zero)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleTap(at: value.location)
                }
        )
    }

    private func handleTap(at location: CGPoint) {
        let padding: CGFloat = 40
        let plotWidth = size.width - 2 * padding
        let plotHeight = size.height - 2 * padding

        let (minVal, maxVal) = bounds
        let range = maxVal - minVal

        // Find nearest feature to tap location
        var nearestFeature: PersistenceFeature?
        var minDistance: CGFloat = .infinity

        for feature in features {
            guard let death = feature.death, !feature.isInfinite else { continue }

            let x = padding + CGFloat((feature.birth - minVal) / range) * plotWidth
            let y = size.height - padding - CGFloat((death - minVal) / range) * plotHeight
            let point = CGPoint(x: x, y: y)

            let distance = hypot(point.x - location.x, point.y - location.y)

            if distance < 20 && distance < minDistance {
                minDistance = distance
                nearestFeature = feature
            }
        }

        withAnimation(.spring(response: 0.3)) {
            selectedFeature = nearestFeature
        }
    }
}


// MARK: - Feature Detail Card

struct FeatureDetailCard: View {
    let feature: PersistenceFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(feature.color)
                    .frame(width: 16, height: 16)

                Text(feature.homologyClass)
                    .font(.headline)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Birth:")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.4f", feature.birth))
                        .fontWeight(.medium)
                }

                GridRow {
                    Text("Death:")
                        .foregroundStyle(.secondary)
                    if feature.isInfinite {
                        Text("∞")
                            .fontWeight(.medium)
                    } else if let death = feature.death {
                        Text(String(format: "%.4f", death))
                            .fontWeight(.medium)
                    }
                }

                GridRow {
                    Text("Lifetime:")
                        .foregroundStyle(.secondary)
                    Text(feature.displayLifetime)
                        .fontWeight(.medium)
                }

                GridRow {
                    Text("Dimension:")
                        .foregroundStyle(.secondary)
                    Text("H\(feature.dimension)")
                        .fontWeight(.medium)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(feature.color.opacity(0.1))
        .cornerRadius(CoastalCorners.standard)
    }
}

// MARK: - Persistence Diagram Legend

struct PersistenceDiagramLegend: View {
    let features: [PersistenceFeature]

    private var stats: [(dimension: Int, count: Int, color: Color)] {
        [
            (0, features.filter { $0.dimension == 0 }.count, .h0Color),
            (1, features.filter { $0.dimension == 1 }.count, .h1Color),
            (2, features.filter { $0.dimension == 2 }.count, .h2Color)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                ForEach(stats, id: \.dimension) { stat in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(stat.color)
                            .frame(width: 10, height: 10)
                        Text("H\(stat.dimension)")
                            .font(.caption)
                        Text("(\(stat.count))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Total features
                Text("\(features.count) total features")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.tight)
    }
}

// MARK: - Preview

#Preview {
    // Sample data for preview
    let sampleFeatures: [PersistenceFeature] = [
        PersistenceFeature(id: 0, birth: 0.0, death: 10.1, lifetime: 10.1, dimension: 0, homologyClass: "H0"),
        PersistenceFeature(id: 1, birth: 0.5, death: 14.1, lifetime: 13.6, dimension: 0, homologyClass: "H0"),
        PersistenceFeature(id: 2, birth: 2.3, death: 5.8, lifetime: 3.5, dimension: 1, homologyClass: "H1"),
        PersistenceFeature(id: 3, birth: 3.1, death: 7.2, lifetime: 4.1, dimension: 1, homologyClass: "H1"),
        PersistenceFeature(id: 4, birth: 4.5, death: 6.8, lifetime: 2.3, dimension: 2, homologyClass: "H2"),
        PersistenceFeature(id: 5, birth: 1.2, death: 8.5, lifetime: 7.3, dimension: 0, homologyClass: "H0"),
        PersistenceFeature(id: 6, birth: 5.5, death: 9.2, lifetime: 3.7, dimension: 1, homologyClass: "H1"),
    ]

    NavigationStack {
        PersistenceDiagramView(features: sampleFeatures, bandName: "Band 01")
    }
}
