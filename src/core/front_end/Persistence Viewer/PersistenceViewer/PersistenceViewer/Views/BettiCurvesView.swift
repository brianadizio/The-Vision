//
//  BettiCurvesView.swift
//  PersistenceViewer
//
//  Betti number curves visualization
//  Shows evolution of H0, H1, H2 over distance thresholds
//

import SwiftUI

struct BettiCurvesView: View {
    let bettiCurves: BettiCurveData
    let bandName: String

    @State private var showH0: Bool = true
    @State private var showH1: Bool = true
    @State private var showH2: Bool = true
    @State private var selectedThresholdIndex: Int? = nil
    @State private var showValues: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("Betti Numbers")
                    .font(.headline)

                Spacer()

                // Dimension toggles
                HStack(spacing: 16) {
                    DimensionToggle(
                        dimension: 0,
                        isOn: $showH0,
                        color: .h0Color,
                        label: "H₀"
                    )
                    DimensionToggle(
                        dimension: 1,
                        isOn: $showH1,
                        color: .h1Color,
                        label: "H₁"
                    )
                    DimensionToggle(
                        dimension: 2,
                        isOn: $showH2,
                        color: .h2Color,
                        label: "H₂"
                    )

                    // Values toggle
                    Button(action: {
                        withAnimation {
                            showValues.toggle()
                        }
                    }) {
                        Image(systemName: showValues ? "number.circle.fill" : "number.circle")
                            .foregroundColor(showValues ? .coastalPrimary : .secondary)
                    }
                }
            }
            .padding()

            // Main chart
            GeometryReader { geometry in
                BettiCurvesChart(
                    bettiCurves: bettiCurves,
                    showH0: showH0,
                    showH1: showH1,
                    showH2: showH2,
                    selectedThresholdIndex: $selectedThresholdIndex,
                    showValues: showValues,
                    size: geometry.size
                )
            }
            .background(Color.coastalBackground)
            .cornerRadius(CoastalCorners.standard)
            .padding(.horizontal)

            // Selected threshold details
            if let index = selectedThresholdIndex,
               index < bettiCurves.nBins {
                ThresholdDetailCard(
                    bettiCurves: bettiCurves,
                    thresholdIndex: index
                )
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Statistics summary
            BettiStatisticsPanel(bettiCurves: bettiCurves)
                .padding()
        }
        .navigationTitle(bandName)
    }
}

// MARK: - Betti Curves Chart

struct BettiCurvesChart: View {
    let bettiCurves: BettiCurveData
    let showH0: Bool
    let showH1: Bool
    let showH2: Bool
    @Binding var selectedThresholdIndex: Int?
    let showValues: Bool
    let size: CGSize

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 50
            let plotWidth = size.width - 2 * padding
            let plotHeight = size.height - 2 * padding

            // Get data ranges
            let maxBetti = getMaxBettiValue()
            guard maxBetti > 0 else { return }

            // Helper to convert data to screen coordinates
            func toScreen(bin: Int, value: Double) -> CGPoint {
                let x = padding + CGFloat(bin) / CGFloat(max(bettiCurves.nBins - 1, 1)) * plotWidth
                let y = size.height - padding - CGFloat(value / maxBetti) * plotHeight
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

            // Draw grid lines
            let numGridLines = 5
            for i in 0...numGridLines {
                let value = maxBetti * Double(i) / Double(numGridLines)
                let y = size.height - padding - CGFloat(value / maxBetti) * plotHeight

                let gridPath = Path { path in
                    path.move(to: CGPoint(x: padding, y: y))
                    path.addLine(to: CGPoint(x: size.width - padding, y: y))
                }
                context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

                // Y-axis label
                if showValues {
                    var yLabelContext = context
                    yLabelContext.translateBy(x: padding - 30, y: y)
                    yLabelContext.draw(
                        Text(String(format: "%.0f", value)).font(.caption2),
                        at: .zero
                    )
                }
            }

            // Draw vertical grid lines
            let numVerticalLines = 10
            for i in 0...numVerticalLines {
                let x = padding + CGFloat(i) / CGFloat(numVerticalLines) * plotWidth

                let gridPath = Path { path in
                    path.move(to: CGPoint(x: x, y: padding))
                    path.addLine(to: CGPoint(x: x, y: size.height - padding))
                }
                context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
            }

            // Draw Betti curves with coastal colors
            if showH0, let h0Data = getBettiData(dimension: 0) {
                drawCurve(context: context, data: h0Data, color: .h0Color, toScreen: toScreen)
            }

            if showH1, let h1Data = getBettiData(dimension: 1) {
                drawCurve(context: context, data: h1Data, color: .h1Color, toScreen: toScreen)
            }

            if showH2, let h2Data = getBettiData(dimension: 2) {
                drawCurve(context: context, data: h2Data, color: .h2Color, toScreen: toScreen)
            }

            // Draw selected threshold line
            if let index = selectedThresholdIndex, index < bettiCurves.nBins {
                let x = padding + CGFloat(index) / CGFloat(max(bettiCurves.nBins - 1, 1)) * plotWidth

                let selectionPath = Path { path in
                    path.move(to: CGPoint(x: x, y: padding))
                    path.addLine(to: CGPoint(x: x, y: size.height - padding))
                }
                context.stroke(
                    selectionPath,
                    with: .color(.sunsetOrange),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                )

                // Draw selection circle at intersection points
                if showH0, let h0Data = getBettiData(dimension: 0), index < h0Data.count {
                    let point = toScreen(bin: index, value: h0Data[index])
                    drawPoint(context: context, at: point, color: .h0Color)
                }
                if showH1, let h1Data = getBettiData(dimension: 1), index < h1Data.count {
                    let point = toScreen(bin: index, value: h1Data[index])
                    drawPoint(context: context, at: point, color: .h1Color)
                }
                if showH2, let h2Data = getBettiData(dimension: 2), index < h2Data.count {
                    let point = toScreen(bin: index, value: h2Data[index])
                    drawPoint(context: context, at: point, color: .h2Color)
                }
            }

            // Draw axis labels
            var xLabelContext = context
            xLabelContext.translateBy(x: size.width / 2, y: size.height - 10)
            xLabelContext.draw(Text("Distance Threshold").font(.caption), at: .zero)

            var yLabelContext = context
            yLabelContext.translateBy(x: 15, y: size.height / 2)
            yLabelContext.rotate(by: .degrees(-90))
            yLabelContext.draw(Text("Betti Number").font(.caption), at: .zero)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleTap(at: value.location)
                }
        )
    }

    // MARK: - Helper Functions

    private func drawCurve(
        context: GraphicsContext,
        data: [Double],
        color: Color,
        toScreen: (Int, Double) -> CGPoint
    ) {
        guard !data.isEmpty else { return }

        let path = Path { path in
            let startPoint = toScreen(0, data[0])
            path.move(to: startPoint)

            for (index, value) in data.enumerated() {
                let point = toScreen(index, value)
                path.addLine(to: point)
            }
        }

        // Draw filled area under curve
        let fillPath = Path { path in
            let startPoint = toScreen(0, data[0])
            path.move(to: CGPoint(x: startPoint.x, y: size.height - 50))
            path.addLine(to: startPoint)

            for (index, value) in data.enumerated() {
                let point = toScreen(index, value)
                path.addLine(to: point)
            }

            let endPoint = toScreen(data.count - 1, data.last!)
            path.addLine(to: CGPoint(x: endPoint.x, y: size.height - 50))
            path.closeSubpath()
        }

        context.fill(fillPath, with: .color(color.opacity(0.1)))
        context.stroke(path, with: .color(color), lineWidth: 2)
    }

    private func drawPoint(context: GraphicsContext, at point: CGPoint, color: Color) {
        let circle = Path { path in
            path.addEllipse(in: CGRect(
                x: point.x - 6,
                y: point.y - 6,
                width: 12,
                height: 12
            ))
        }
        context.fill(circle, with: .color(color))
        context.stroke(circle, with: .color(.white), lineWidth: 2)
    }

    private func handleTap(at location: CGPoint) {
        let padding: CGFloat = 50
        let plotWidth = size.width - 2 * padding

        // Convert screen x to bin index
        let relativeX = location.x - padding
        guard relativeX >= 0 && relativeX <= plotWidth else {
            selectedThresholdIndex = nil
            return
        }

        let binIndex = Int((relativeX / plotWidth) * CGFloat(bettiCurves.nBins))
        selectedThresholdIndex = min(max(binIndex, 0), bettiCurves.nBins - 1)
    }

    private func getBettiData(dimension: Int) -> [Double]? {
        guard dimension >= 0 && dimension < bettiCurves.dimensions.count else { return nil }

        // Extract column for this dimension
        return bettiCurves.values.map { row in
            guard dimension < row.count else { return 0.0 }
            return row[dimension]
        }
    }

    private func getMaxBettiValue() -> Double {
        var maxValue = 0.0

        if showH0, let h0Data = getBettiData(dimension: 0) {
            maxValue = max(maxValue, h0Data.max() ?? 0)
        }
        if showH1, let h1Data = getBettiData(dimension: 1) {
            maxValue = max(maxValue, h1Data.max() ?? 0)
        }
        if showH2, let h2Data = getBettiData(dimension: 2) {
            maxValue = max(maxValue, h2Data.max() ?? 0)
        }

        return max(maxValue, 1) // Ensure at least 1 to avoid division by zero
    }
}

// MARK: - Threshold Detail Card

struct ThresholdDetailCard: View {
    let bettiCurves: BettiCurveData
    let thresholdIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Threshold Index: \(thresholdIndex)")
                    .font(.headline)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                if thresholdIndex < bettiCurves.values.count {
                    let values = bettiCurves.values[thresholdIndex]

                    if values.count > 0 {
                        GridRow {
                            Circle().fill(Color.h0Color).frame(width: 12, height: 12)
                            Text("H₀:").foregroundStyle(.secondary)
                            Text(String(format: "%.0f", values[0]))
                                .fontWeight(.medium)
                        }
                    }

                    if values.count > 1 {
                        GridRow {
                            Circle().fill(Color.h1Color).frame(width: 12, height: 12)
                            Text("H₁:").foregroundStyle(.secondary)
                            Text(String(format: "%.0f", values[1]))
                                .fontWeight(.medium)
                        }
                    }

                    if values.count > 2 {
                        GridRow {
                            Circle().fill(Color.h2Color).frame(width: 12, height: 12)
                            Text("H₂:").foregroundStyle(.secondary)
                            Text(String(format: "%.0f", values[2]))
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
}

// MARK: - Betti Statistics Panel

struct BettiStatisticsPanel: View {
    let bettiCurves: BettiCurveData

    private func getStats(dimension: Int) -> (max: Double, mean: Double, total: Double)? {
        guard dimension >= 0 && dimension < bettiCurves.dimensions.count else { return nil }

        let values = bettiCurves.values.compactMap { row -> Double? in
            guard dimension < row.count else { return nil }
            return row[dimension]
        }

        guard !values.isEmpty else { return nil }

        let max = values.max() ?? 0
        let mean = values.reduce(0, +) / Double(values.count)
        let total = values.reduce(0, +)

        return (max, mean, total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                // H0 stats
                if let stats = getStats(dimension: 0) {
                    StatColumn(
                        label: "H₀",
                        color: .h0Color,
                        max: stats.max,
                        mean: stats.mean
                    )
                }

                // H1 stats
                if let stats = getStats(dimension: 1) {
                    StatColumn(
                        label: "H₁",
                        color: .h1Color,
                        max: stats.max,
                        mean: stats.mean
                    )
                }

                // H2 stats
                if let stats = getStats(dimension: 2) {
                    StatColumn(
                        label: "H₂",
                        color: .h2Color,
                        max: stats.max,
                        mean: stats.mean
                    )
                }
            }

            Text("\(bettiCurves.nBins) distance thresholds")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.tight)
    }
}

struct StatColumn: View {
    let label: String
    let color: Color
    let max: Double
    let mean: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Max:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f", max))
                        .font(.caption2)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Mean:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", mean))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    // Sample Betti curve data
    let sampleValues: [[Double]] = (0..<100).map { i in
        let t = Double(i) / 100.0
        return [
            100 - Double(i) * 0.5,  // H0: decreasing
            sin(t * 3.14 * 4) * 20 + 25,  // H1: oscillating
            max(0, 10 - abs(Double(i) - 50) * 0.3)  // H2: peak in middle
        ]
    }

    let sampleBettiCurves = BettiCurveData(
        values: sampleValues,
        nBins: 100,
        dimensions: ["H0", "H1", "H2"]
    )

    NavigationStack {
        BettiCurvesView(
            bettiCurves: sampleBettiCurves,
            bandName: "Band 01"
        )
    }
}
