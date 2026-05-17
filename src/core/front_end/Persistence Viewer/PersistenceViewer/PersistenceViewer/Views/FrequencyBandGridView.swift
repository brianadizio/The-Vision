//
//  FrequencyBandGridView.swift
//  PersistenceViewer
//
//  Grid overview of all frequency bands with visual previews
//  Shows complexity-based coloring and animation scrubber
//

import SwiftUI

struct FrequencyBandGridView: View {
    let config: Configuration
    let experimentName: String

    @State private var selectedBand: Band?
    @State private var showingDetail = false
    @State private var animationIndex: Int = 0
    @State private var isAnimating = false
    @State private var sortMode: BandSortMode = .frequency
    @State private var colorMode: BandColorMode = .complexity

    enum BandSortMode: String, CaseIterable {
        case frequency = "Frequency"
        case complexity = "Complexity"
        case h0Count = "H₀ Count"
        case h1Count = "H₁ Count"
    }

    enum BandColorMode: String, CaseIterable {
        case complexity = "Complexity"
        case h0Count = "H₀"
        case h1Count = "H₁"
        case h2Count = "H₂"
    }

    var sortedBands: [Band] {
        let bands = config.bands
        switch sortMode {
        case .frequency:
            return bands.sorted { $0.bandId < $1.bandId }
        case .complexity:
            return bands.sorted { complexityScore($0) > complexityScore($1) }
        case .h0Count:
            return bands.sorted { featureCount($0, dim: "H0") > featureCount($1, dim: "H0") }
        case .h1Count:
            return bands.sorted { featureCount($0, dim: "H1") > featureCount($1, dim: "H1") }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            VStack(spacing: 12) {
                HStack {
                    Text("Frequency Band Grid")
                        .font(.headline)

                    Spacer()

                    // Animation control
                    Button(action: {
                        isAnimating.toggle()
                        if isAnimating {
                            startAnimation()
                        }
                    }) {
                        Image(systemName: isAnimating ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }

                // Sort and color controls
                HStack(spacing: 16) {
                    // Sort mode
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sort by:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("Sort", selection: $sortMode) {
                            ForEach(BandSortMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()
                        .frame(height: 30)

                    // Color mode
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Color by:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("Color", selection: $colorMode) {
                            ForEach(BandColorMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding()
            .background(Color.coastalBackground)

            // Animation scrubber
            if isAnimating || animationIndex > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Band \(animationIndex + 1)")
                            .font(.caption)
                            .fontWeight(.medium)

                        Spacer()

                        Text("\(animationIndex + 1) / \(config.bands.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(animationIndex) },
                            set: { animationIndex = Int($0) }
                        ),
                        in: 0...Double(max(config.bands.count - 1, 0)),
                        step: 1
                    )
                    .disabled(isAnimating)
                }
                .padding()
                .background(Color.coastalWater.opacity(0.1))
            }

            // Grid of bands
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(sortedBands) { band in
                        BandGridCard(
                            band: band,
                            colorMode: colorMode,
                            isHighlighted: isAnimating && sortedBands[animationIndex].id == band.id,
                            experimentName: experimentName
                        )
                        .onTapGesture {
                            selectedBand = band
                            showingDetail = true
                        }
                    }
                }
                .padding()
            }

            // Statistics summary
            GridStatisticsSummary(config: config)
                .padding()
        }
        .navigationTitle("Config \(config.configId)")
        .navigationDestination(isPresented: $showingDetail) {
            if let band = selectedBand {
                BandDetailView(band: band, experimentName: experimentName)
            }
        }
    }

    // MARK: - Helper Functions

    private func complexityScore(_ band: Band) -> Int {
        // Higher score = more complex topology
        let h0 = featureCount(band, dim: "H0")
        let h1 = featureCount(band, dim: "H1")
        let h2 = featureCount(band, dim: "H2")

        // Weight higher dimensions more heavily
        return h0 + (h1 * 3) + (h2 * 5)
    }

    private func featureCount(_ band: Band, dim: String) -> Int {
        band.statistics?[dim]?.count ?? 0
    }

    private func startAnimation() {
        animationIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isAnimating {
                timer.invalidate()
                return
            }

            animationIndex += 1

            if animationIndex >= config.bands.count {
                animationIndex = 0 // Loop
            }
        }
    }
}

// MARK: - Band Grid Card

struct BandGridCard: View {
    let band: Band
    let colorMode: FrequencyBandGridView.BandColorMode
    let isHighlighted: Bool
    let experimentName: String

    private var cardColor: Color {
        switch colorMode {
        case .complexity:
            return CoastalColorMapping.complexityColor(for: complexityScore)
        case .h0Count:
            return CoastalColorMapping.countColor(for: featureCount("H0"))
        case .h1Count:
            return CoastalColorMapping.countColor(for: featureCount("H1"))
        case .h2Count:
            return CoastalColorMapping.countColor(for: featureCount("H2"))
        }
    }

    private var complexityScore: Int {
        let h0 = featureCount("H0")
        let h1 = featureCount("H1")
        let h2 = featureCount("H2")
        return h0 + (h1 * 3) + (h2 * 5)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with band number
            HStack {
                Text("Band \(band.bandId)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                // Complexity indicator
                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .padding(8)
            .background(cardColor)

            // Mini visualization preview
            VStack(spacing: 8) {
                // Betti curve mini preview
                if let bettiCurves = band.bettiCurves {
                    BettiCurveMiniPreview(bettiCurves: bettiCurves)
                        .frame(height: 60)
                        .background(Color.black.opacity(0.02))
                        .cornerRadius(6)
                }

                // Statistics
                if let stats = band.statistics {
                    HStack(spacing: 8) {
                        FeatureBadge(label: "H₀", count: stats["H0"]?.count ?? 0, color: .h0Color)
                        FeatureBadge(label: "H₁", count: stats["H1"]?.count ?? 0, color: .h1Color)
                        FeatureBadge(label: "H₂", count: stats["H2"]?.count ?? 0, color: .h2Color)
                    }
                    .font(.caption2)
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .cornerRadius(CoastalCorners.standard)
        .shadow(color: isHighlighted ? CoastalShadows.glow(.coastalWater) : CoastalShadows.medium, radius: isHighlighted ? 8 : 4, x: 0, y: isHighlighted ? 4 : 2)
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(CoastalAnimations.ripple, value: isHighlighted)
    }

    private func featureCount(_ dim: String) -> Int {
        band.statistics?[dim]?.count ?? 0
    }
}

// MARK: - Betti Curve Mini Preview

struct BettiCurveMiniPreview: View {
    let bettiCurves: BettiCurveData

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 4
            let plotWidth = size.width - 2 * padding
            let plotHeight = size.height - 2 * padding

            // Get max value
            let allValues = bettiCurves.values.flatMap { $0 }
            let maxValue = allValues.max() ?? 1.0

            func toScreen(bin: Int, value: Double) -> CGPoint {
                let x = padding + CGFloat(bin) / CGFloat(max(bettiCurves.nBins - 1, 1)) * plotWidth
                let y = size.height - padding - CGFloat(value / maxValue) * plotHeight
                return CGPoint(x: x, y: y)
            }

            // Draw simplified curves with coastal colors
            let colors: [Color] = [.h0Color, .h1Color, .h2Color]
            for dim in 0..<min(3, bettiCurves.dimensions.count) {
                let values = bettiCurves.values.compactMap { row -> Double? in
                    guard dim < row.count else { return nil }
                    return row[dim]
                }

                guard !values.isEmpty else { continue }

                let path = Path { path in
                    let startPoint = toScreen(bin: 0, value: values[0])
                    path.move(to: startPoint)

                    for (index, value) in values.enumerated() {
                        let point = toScreen(bin: index, value: value)
                        path.addLine(to: point)
                    }
                }

                context.stroke(path, with: .color(colors[dim].opacity(0.7)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Feature Badge

struct FeatureBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
            Text(label)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .fontWeight(.medium)
        }
    }
}

// MARK: - Grid Statistics Summary

struct GridStatisticsSummary: View {
    let config: Configuration

    private var totalFeatures: (h0: Int, h1: Int, h2: Int) {
        var h0 = 0, h1 = 0, h2 = 0

        for band in config.bands {
            if let stats = band.statistics {
                h0 += stats["H0"]?.count ?? 0
                h1 += stats["H1"]?.count ?? 0
                h2 += stats["H2"]?.count ?? 0
            }
        }

        return (h0, h1, h2)
    }

    private var avgComplexity: Double {
        let total = config.bands.reduce(0) { sum, band in
            let h0 = band.statistics?["H0"]?.count ?? 0
            let h1 = band.statistics?["H1"]?.count ?? 0
            let h2 = band.statistics?["H2"]?.count ?? 0
            return sum + h0 + (h1 * 3) + (h2 * 5)
        }
        return Double(total) / Double(max(config.bands.count, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                // Total bands
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bands")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(config.bands.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 40)

                // Feature counts
                HStack(spacing: 16) {
                    FeatureColumn(label: "H₀", count: totalFeatures.h0, color: .h0Color)
                    FeatureColumn(label: "H₁", count: totalFeatures.h1, color: .h1Color)
                    FeatureColumn(label: "H₂", count: totalFeatures.h2, color: .h2Color)
                }

                Spacer()

                // Average complexity
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Complexity")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", avgComplexity))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.sunsetOrange)
                }
            }
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.standard)
    }
}

struct FeatureColumn: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    // Create sample bands
    let sampleBands: [Band] = (1...20).map { i in
        let h0Count = Int.random(in: 2...10)
        let h1Count = Int.random(in: 0...20)
        let h2Count = Int.random(in: 0...5)

        let stats: [String: HomologyStatistics] = [
            "H0": HomologyStatistics(count: h0Count, meanLifetime: 5.0, maxLifetime: 10.0, totalPersistence: 50.0),
            "H1": HomologyStatistics(count: h1Count, meanLifetime: 2.0, maxLifetime: 5.0, totalPersistence: 20.0),
            "H2": HomologyStatistics(count: h2Count, meanLifetime: 1.0, maxLifetime: 2.0, totalPersistence: 5.0)
        ]

        // Sample Betti curves
        let bettiValues: [[Double]] = (0..<100).map { j in
            let t = Double(j) / 100.0
            return [
                Double(h0Count) * (1.0 - t),
                Double(h1Count) * sin(t * 3.14 * 2),
                Double(h2Count) * max(0, sin(t * 3.14))
            ]
        }

        let bettiCurves = BettiCurveData(
            values: bettiValues,
            nBins: 100,
            dimensions: ["H0", "H1", "H2"]
        )

        return Band(
            configId: 1,
            bandId: i,
            persistenceDiagram: nil,
            statistics: stats,
            bettiCurves: bettiCurves,
            persistenceLandscape: nil,
            pointCloud: nil,
            metadata: nil
        )
    }

    let sampleConfig = Configuration(
        configId: 1,
        bands: sampleBands
    )

    NavigationStack {
        FrequencyBandGridView(
            config: sampleConfig,
            experimentName: "Test Experiment"
        )
    }
}
