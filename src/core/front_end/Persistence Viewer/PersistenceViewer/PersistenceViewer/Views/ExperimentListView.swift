//
//  ExperimentListView.swift
//  PersistenceViewer
//
//  Main view for browsing and selecting experiments.
//  Updated for PROMPT-VISION-001: Universal TDA import with Solution-based grouping.
//

import SwiftUI
import RealityKit

struct ExperimentListView: View {
    @StateObject private var dataLoader = UniversalDataLoader()

    var body: some View {
        NavigationStack {
            Group {
                if dataLoader.isLoading {
                    ProgressView("Loading experiments...")
                        .progressViewStyle(.circular)
                } else if let error = dataLoader.error {
                    ErrorView(error: error) {
                        dataLoader.loadExperiments()
                    }
                } else if dataLoader.experiments.isEmpty {
                    EmptyStateView()
                } else {
                    UniversalExperimentList(dataLoader: dataLoader)
                }
            }
            .navigationTitle("Persistence Diagrams")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dataLoader.loadExperiments()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            dataLoader.loadExperiments()
        }
    }
}

// MARK: - Universal Experiment List (grouped by Solution)

struct UniversalExperimentList: View {
    @ObservedObject var dataLoader: UniversalDataLoader
    
    var body: some View {
        List {
            ForEach(dataLoader.sortedSolutions, id: \.self) { source in
                Section {
                    if let experiments = dataLoader.groupedBySolution[source] {
                        ForEach(experiments) { experiment in
                            NavigationLink(destination: UniversalExperimentDetailView(experiment: experiment)) {
                                UniversalExperimentRow(experiment: experiment)
                            }
                        }
                    }
                } header: {
                    SolutionSectionHeader(source: source)
                }
            }
        }
    }
}

// MARK: - Solution Section Header

struct SolutionSectionHeader: View {
    let source: SolutionSource
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: source.systemImage)
                .foregroundStyle(source.tintColor)
            Text(source.displayName)
                .font(.headline)
            if let version = source.exportVersion {
                Text("v\(version)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Universal Experiment Row

struct UniversalExperimentRow: View {
    let experiment: UniversalTDAExperiment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(experiment.name)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(experiment.datasetCount) datasets", systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(experiment.totalFeatureCount) features", systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let desc = experiment.description {
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
            
            if let timestamp = experiment.source.exportTimestamp {
                Text(formatDate(timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Universal Experiment Detail View

struct UniversalExperimentDetailView: View {
    let experiment: UniversalTDAExperiment
    
    /// Group datasets by their groupName
    private var groupedDatasets: [(String, [TDADataset])] {
        let grouped = Dictionary(grouping: experiment.datasets, by: { $0.groupName ?? "Ungrouped" })
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        List {
            // Global visualizations section
            if let globalViz = experiment.globalVisualizations {
                Section("Global Visualizations") {
                    // Phase Space Trajectory
                    if let phaseSpace = globalViz.phaseSpace {
                        NavigationLink(destination: PhaseSpaceTrajectoryView(
                            phaseSpace: phaseSpace,
                            experimentName: experiment.name
                        )) {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text("Phase Space Trajectory")
                                        .font(.subheadline)
                                    Text("\(phaseSpace.nPoints) points")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Global PCA
                    if let globalPCA = globalViz.globalPCA {
                        NavigationLink(destination: PointCloud3DView(
                            pointCloud: PointCloudData(
                                points: globalPCA.points,
                                nPoints: globalPCA.nPoints,
                                dimensions: globalPCA.dimensions
                            ),
                            bandName: "Global PCA Space"
                        )) {
                            HStack {
                                Image(systemName: "cube.transparent")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Global PCA Space")
                                        .font(.subheadline)
                                    Text("\(globalPCA.nPoints) points")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Manifold Embeddings
                    if let manifoldEmbeddings = globalViz.manifoldEmbeddings {
                        NavigationLink(destination: ManifoldEmbeddingView(
                            manifolds: manifoldEmbeddings,
                            labels: globalViz.scattererLabels,
                            experimentName: experiment.name
                        )) {
                            HStack {
                                Image(systemName: "chart.3d")
                                    .foregroundColor(.teal)
                                VStack(alignment: .leading) {
                                    Text("Manifold Embeddings")
                                        .font(.subheadline)
                                    Text("\(manifoldEmbeddings.availableTypes.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Datasets grouped by group name
            ForEach(groupedDatasets, id: \.0) { groupName, datasets in
                Section(groupName) {
                    ForEach(datasets) { dataset in
                        NavigationLink(destination: UniversalDatasetDetailView(
                            dataset: dataset,
                            experimentName: experiment.name
                        )) {
                            DatasetRow(dataset: dataset, tintColor: experiment.source.tintColor)
                        }
                    }
                }
            }
        }
        .navigationTitle(experiment.name)
    }
}

// MARK: - Dataset Row

struct DatasetRow: View {
    let dataset: TDADataset
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dataset.displayName)
                .font(.headline)

            if let stats = dataset.statistics {
                HStack(spacing: 12) {
                    if let h0 = stats["H0"] {
                        StatBadge(label: "H0", count: h0.count, color: .blue)
                    }
                    if let h1 = stats["H1"] {
                        StatBadge(label: "H1", count: h1.count, color: .green)
                    }
                    if let h2 = stats["H2"] {
                        StatBadge(label: "H2", count: h2.count, color: .red)
                    }
                }
            }
            
            // Show available visualization types
            HStack(spacing: 8) {
                if dataset.persistenceDiagram != nil {
                    MiniTag(text: "PD", color: tintColor)
                }
                if dataset.bettiCurves != nil {
                    MiniTag(text: "Betti", color: tintColor)
                }
                if dataset.pointCloud != nil {
                    MiniTag(text: "3D", color: tintColor)
                }
                if dataset.persistenceLandscape != nil {
                    MiniTag(text: "PL", color: tintColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mini Tag

struct MiniTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

// MARK: - Universal Dataset Detail View

struct UniversalDatasetDetailView: View {
    let dataset: TDADataset
    let experimentName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statistics Section
                if let stats = dataset.statistics {
                    StatisticsSection(statistics: stats)
                }

                // Persistence Diagram
                if let diagram = dataset.persistenceDiagram {
                    PersistenceDiagramSection(features: diagram, bandName: dataset.displayName)
                }

                // Betti Curves
                if let bettiCurves = dataset.bettiCurves {
                    BettiCurvesSection(bettiCurves: bettiCurves, bandName: dataset.displayName)
                }

                // Persistence Landscape
                if let landscape = dataset.persistenceLandscape {
                    PersistenceLandscapeSection(landscape: landscape, bandName: dataset.displayName)
                }

                // Point Cloud
                if let pointCloud = dataset.pointCloud {
                    PointCloudInfoSection(pointCloud: pointCloud, bandName: dataset.displayName)
                }
                
                // Metadata section
                if let metadata = dataset.metadata, !metadata.isEmpty {
                    MetadataSection(metadata: metadata)
                }
            }
            .padding()
        }
        .navigationTitle(dataset.displayName)
    }
}

// MARK: - Metadata Section

struct MetadataSection: View {
    let metadata: [String: AnyCodable]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.title2)
                .bold()
            
            ForEach(metadata.keys.sorted(), id: \.self) { key in
                HStack {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(String(describing: metadata[key]?.value ?? "—"))")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(12)
    }
}

// MARK: - Legacy Compatibility Views (kept for backward compat)

/// Wraps the old ConfigurationListView interface for legacy experiments
struct ConfigurationListView: View {
    let experiment: PersistenceExperiment

    var body: some View {
        // Convert to universal and show
        let universal = LegacyFormatAdapter.convert(experiment)
        UniversalExperimentDetailView(experiment: universal)
    }
}

// MARK: - Configuration Row

struct ConfigurationRow: View {
    let config: Configuration

    private var totalFeatures: Int {
        config.bands.reduce(0) { sum, band in
            let h0 = band.statistics?["H0"]?.count ?? 0
            let h1 = band.statistics?["H1"]?.count ?? 0
            let h2 = band.statistics?["H2"]?.count ?? 0
            return sum + h0 + h1 + h2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Configuration \(config.configId)")
                .font(.headline)

            HStack(spacing: 12) {
                Label("\(config.bands.count) bands", systemImage: "waveform.path")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(totalFeatures) features", systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Band List View

struct BandListView: View {
    let config: Configuration
    let experimentName: String

    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list
        case grid
    }

    var body: some View {
        Group {
            if viewMode == .list {
                List(config.bands) { band in
                    NavigationLink(destination: BandDetailView(band: band, experimentName: experimentName)) {
                        BandRow(band: band)
                    }
                }
            } else {
                FrequencyBandGridView(config: config, experimentName: experimentName)
            }
        }
        .navigationTitle("Config \(config.configId)")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        viewMode = viewMode == .list ? .grid : .list
                    }
                }) {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                }
            }
        }
    }
}

// MARK: - Band Row

struct BandRow: View {
    let band: Band

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(band.displayName)
                .font(.headline)

            if let stats = band.statistics {
                HStack(spacing: 12) {
                    if let h0 = stats["H0"] {
                        StatBadge(label: "H0", count: h0.count, color: .blue)
                    }
                    if let h1 = stats["H1"] {
                        StatBadge(label: "H1", count: h1.count, color: .green)
                    }
                    if let h2 = stats["H2"] {
                        StatBadge(label: "H2", count: h2.count, color: .red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label): \(count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Band Detail View

struct BandDetailView: View {
    let band: Band
    let experimentName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let stats = band.statistics {
                    StatisticsSection(statistics: stats)
                }
                if let diagram = band.persistenceDiagram {
                    PersistenceDiagramSection(features: diagram, bandName: band.displayName)
                }
                if let bettiCurves = band.bettiCurves {
                    BettiCurvesSection(bettiCurves: bettiCurves, bandName: band.displayName)
                }
                if let landscape = band.persistenceLandscape {
                    PersistenceLandscapeSection(landscape: landscape, bandName: band.displayName)
                }
                if let pointCloud = band.pointCloud {
                    PointCloudInfoSection(pointCloud: pointCloud, bandName: band.displayName)
                }
            }
            .padding()
        }
        .navigationTitle(band.displayName)
    }
}

// MARK: - Statistics Section

struct StatisticsSection: View {
    let statistics: [String: HomologyStatistics]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Homology Statistics")
                .font(.title2)
                .bold()

            ForEach(["H0", "H1", "H2"], id: \.self) { dim in
                if let stat = statistics[dim] {
                    HomologyStatCard(dimension: dim, stats: stat)
                }
            }
        }
    }
}

struct HomologyStatCard: View {
    let dimension: String
    let stats: HomologyStatistics

    var color: Color {
        switch dimension {
        case "H0": return .blue
        case "H1": return .green
        case "H2": return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(dimension)
                    .font(.headline)
                Spacer()
                Text("\(stats.count) features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Mean Lifetime:")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.3f", stats.meanLifetime))
                }
                GridRow {
                    Text("Max Lifetime:")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.3f", stats.maxLifetime))
                }
                GridRow {
                    Text("Total Persistence:")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.3f", stats.totalPersistence))
                }
            }
            .font(.caption)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Persistence Diagram Section

struct PersistenceDiagramSection: View {
    let features: [PersistenceFeature]
    let bandName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Persistence Diagram")
                .font(.title2)
                .bold()

            Text("\(features.count) total features")
                .font(.caption)
                .foregroundStyle(.secondary)

            PersistenceDiagramCanvas(
                features: features,
                selectedFeature: .constant(nil),
                size: CGSize(width: 350, height: 300)
            )
            .frame(height: 300)
            .background(Color(white: 0.95))
            .cornerRadius(12)

            NavigationLink {
                PersistenceDiagramView(
                    features: features,
                    bandName: bandName
                )
            } label: {
                HStack {
                    Text("View Full Diagram")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Betti Curves Section

struct BettiCurvesSection: View {
    let bettiCurves: BettiCurveData
    let bandName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Betti Numbers")
                .font(.title2)
                .bold()

            Text("\(bettiCurves.nBins) distance thresholds")
                .font(.caption)
                .foregroundStyle(.secondary)

            BettiMiniChart(bettiCurves: bettiCurves)
                .frame(height: 150)
                .background(Color(white: 0.95))
                .cornerRadius(12)

            NavigationLink {
                BettiCurvesView(
                    bettiCurves: bettiCurves,
                    bandName: bandName
                )
            } label: {
                HStack {
                    Text("View Full Chart")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Betti Mini Chart

struct BettiMiniChart: View {
    let bettiCurves: BettiCurveData

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 20
            let plotWidth = size.width - 2 * padding
            let plotHeight = size.height - 2 * padding

            let allValues = bettiCurves.values.flatMap { $0 }
            let maxValue = allValues.max() ?? 1

            func toScreen(bin: Int, value: Double) -> CGPoint {
                let x = padding + CGFloat(bin) / CGFloat(max(bettiCurves.nBins - 1, 1)) * plotWidth
                let y = size.height - padding - CGFloat(value / maxValue) * plotHeight
                return CGPoint(x: x, y: y)
            }

            let colors: [Color] = [.blue, .green, .red]
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

                context.stroke(path, with: .color(colors[dim]), lineWidth: 1.5)
            }
        }
    }
}

// MARK: - Persistence Landscape Section

struct PersistenceLandscapeSection: View {
    let landscape: PersistenceLandscapeData
    let bandName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Persistence Landscape")
                .font(.title2)
                .bold()

            Text("\(landscape.numberOfLayers) layers × \(landscape.numberOfBins) bins")
                .font(.caption)
                .foregroundStyle(.secondary)

            LandscapeMiniChart(landscape: landscape)
                .frame(height: 150)
                .background(Color(white: 0.95))
                .cornerRadius(12)

            NavigationLink {
                PersistenceLandscapeView(
                    landscape: landscape,
                    bandName: bandName
                )
            } label: {
                HStack {
                    Text("View Full Landscape")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Landscape Mini Chart

struct LandscapeMiniChart: View {
    let landscape: PersistenceLandscapeData

    var body: some View {
        Canvas { context, size in
            let padding: CGFloat = 20
            let plotWidth = size.width - 2 * padding
            let plotHeight = size.height - 2 * padding

            let allValues = landscape.values.flatMap { $0 }
            let maxValue = allValues.max() ?? 1.0

            func toScreen(bin: Int, value: Double) -> CGPoint {
                let x = padding + CGFloat(bin) / CGFloat(max(landscape.numberOfBins - 1, 1)) * plotWidth
                let y = size.height - padding - CGFloat(value / maxValue) * plotHeight
                return CGPoint(x: x, y: y)
            }

            let colors: [Color] = [.blue, .green, .orange]
            for layer in 0..<min(3, landscape.numberOfLayers) {
                let values = landscape.values[layer]
                let path = Path { path in
                    if let firstValue = values.first {
                        let startPoint = toScreen(bin: 0, value: firstValue)
                        path.move(to: startPoint)
                        for (bin, value) in values.enumerated() {
                            let point = toScreen(bin: bin, value: value)
                            path.addLine(to: point)
                        }
                    }
                }
                context.stroke(path, with: .color(colors[layer]), lineWidth: 1.5)
            }
        }
    }
}

// MARK: - Point Cloud Info Section

struct PointCloudInfoSection: View {
    let pointCloud: PointCloudData
    let bandName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Point Cloud (PCA Space)")
                .font(.title2)
                .bold()

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(pointCloud.nPoints)")
                        .font(.title3)
                        .bold()
                }

                VStack(alignment: .leading) {
                    Text("Dimensions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(pointCloud.dimensions)D")
                        .font(.title3)
                        .bold()
                }
            }

            RealityView { content in
                if let entity = createSimplePointCloud(points: pointCloud.simd3Points) {
                    content.add(entity)
                }
            }
            .frame(height: 250)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)

            NavigationLink {
                PointCloud3DView(
                    pointCloud: pointCloud,
                    bandName: bandName
                )
            } label: {
                HStack {
                    Text("View in 3D")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private func createSimplePointCloud(points: [SIMD3<Float>]) -> ModelEntity? {
        guard !points.isEmpty else { return nil }

        let normalizedPoints = normalizePoints(points)
        let parentEntity = Entity()
        parentEntity.name = "pointCloud"

        for point in normalizedPoints {
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor.blue.withAlphaComponent(0.7))

            let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.015),
                materials: [material]
            )
            sphere.position = point
            parentEntity.addChild(sphere)
        }

        let rotationSpeed: Float = 0.3
        parentEntity.transform.rotation = simd_quatf(angle: rotationSpeed, axis: [0, 1, 0])

        let container = ModelEntity(mesh: .generateBox(size: 0), materials: [])
        container.addChild(parentEntity)
        return container
    }

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
        let scale: Float = maxRange > 0 ? 0.6 / maxRange : 1.0

        return points.map { point in
            (point - center) * scale
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Experiments Found")
                .font(.title2)
                .bold()

            Text("Add TDA data from any Golden Enterprise Solution")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("How to Add Data") {
                // TODO: Show data import instructions
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Error Loading Data")
                .font(.title2)
                .bold()

            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                retry()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ExperimentListView()
}
