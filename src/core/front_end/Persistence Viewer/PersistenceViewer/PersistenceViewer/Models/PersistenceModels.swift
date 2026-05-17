//
//  PersistenceModels.swift
//  PersistenceViewer
//
//  Data models for persistence diagrams and TDA results
//

import Foundation
import SwiftUI
import Combine

// MARK: - Main Experiment Model

struct PersistenceExperiment: Codable, Identifiable {
    let id = UUID()
    let name: String
    let sourcePath: String
    let exportTimestamp: String
    let globalVisualizations: GlobalVisualizations?
    let configurations: [Configuration]

    enum CodingKeys: String, CodingKey {
        case name
        case sourcePath = "source_path"
        case exportTimestamp = "export_timestamp"
        case globalVisualizations = "global_visualizations"
        case configurations
    }

    var configCount: Int {
        configurations.count
    }

    var totalBandCount: Int {
        configurations.reduce(0) { $0 + $1.bands.count }
    }

    var hasGlobalVisualizations: Bool {
        globalVisualizations != nil
    }
}

// MARK: - Global Visualizations

struct GlobalVisualizations: Codable {
    let globalPCA: VisualizationData?
    let phaseSpace: VisualizationData?
    let manifoldEmbeddings: ManifoldEmbeddings?
    let scattererLabels: LabelData?

    enum CodingKeys: String, CodingKey {
        case globalPCA = "global_pca"
        case phaseSpace = "phase_space"
        case manifoldEmbeddings = "manifold_embeddings"
        case scattererLabels = "scatterer_labels"
    }
}

struct VisualizationData: Codable {
    let points: [[Double]]
    let nPoints: Int
    let dimensions: Int
    let description: String?

    enum CodingKeys: String, CodingKey {
        case points
        case nPoints = "n_points"
        case dimensions
        case description
    }

    // Convert to SIMD3 for RealityKit
    var simd3Points: [SIMD3<Float>] {
        points.compactMap { point in
            guard point.count >= 3 else { return nil }
            return SIMD3<Float>(
                Float(point[0]),
                Float(point[1]),
                Float(point[2])
            )
        }
    }
}

struct ManifoldEmbeddings: Codable {
    let isomap: VisualizationData?
    let diffusionMap: VisualizationData?
    let lle: VisualizationData?

    enum CodingKeys: String, CodingKey {
        case isomap
        case diffusionMap = "diffusion_map"
        case lle
    }

    var availableTypes: [String] {
        var types: [String] = []
        if isomap != nil { types.append("Isomap") }
        if diffusionMap != nil { types.append("Diffusion Map") }
        if lle != nil { types.append("LLE") }
        return types
    }
}

struct LabelData: Codable {
    let labels: [Double]
    let nLabels: Int
    let description: String?

    enum CodingKeys: String, CodingKey {
        case labels
        case nLabels = "n_labels"
        case description
    }

    // Convert to Int labels for easy access
    var flatLabels: [Int] {
        labels.map { Int($0) }
    }
}

// MARK: - Configuration Model

struct Configuration: Codable, Identifiable {
    var id: Int { configId }
    let configId: Int
    let bands: [Band]

    enum CodingKeys: String, CodingKey {
        case configId = "config_id"
        case bands
    }
}

// MARK: - Band Model

struct Band: Codable, Identifiable {
    var id: Int { bandId }
    let configId: Int
    let bandId: Int
    let persistenceDiagram: [PersistenceFeature]?
    let statistics: [String: HomologyStatistics]?
    let bettiCurves: BettiCurveData?
    let persistenceLandscape: PersistenceLandscapeData?
    let pointCloud: PointCloudData?
    let metadata: BandMetadata?

    enum CodingKeys: String, CodingKey {
        case configId = "config_id"
        case bandId = "band_id"
        case persistenceDiagram = "persistence_diagram"
        case statistics
        case bettiCurves = "betti_curves"
        case persistenceLandscape = "persistence_landscape"
        case pointCloud = "point_cloud"
        case metadata
    }

    // Computed properties for quick access
    var h0Features: [PersistenceFeature] {
        persistenceDiagram?.filter { $0.dimension == 0 } ?? []
    }

    var h1Features: [PersistenceFeature] {
        persistenceDiagram?.filter { $0.dimension == 1 } ?? []
    }

    var h2Features: [PersistenceFeature] {
        persistenceDiagram?.filter { $0.dimension == 2 } ?? []
    }

    var displayName: String {
        "Band \(bandId)"
    }
}

// MARK: - Persistence Feature

struct PersistenceFeature: Codable, Identifiable {
    let id: Int
    let birth: Double
    let death: Double?
    let lifetime: Double?
    let dimension: Int
    let homologyClass: String

    enum CodingKeys: String, CodingKey {
        case id
        case birth
        case death
        case lifetime
        case dimension
        case homologyClass = "homology_class"
    }

    var isInfinite: Bool {
        death == nil
    }

    var displayLifetime: String {
        if let lifetime = lifetime {
            return String(format: "%.3f", lifetime)
        }
        return "∞"
    }

    var color: Color {
        switch dimension {
        case 0: return .blue      // H0: connected components
        case 1: return .green     // H1: loops/holes
        case 2: return .red       // H2: voids
        default: return .gray
        }
    }
}

// MARK: - Homology Statistics

struct HomologyStatistics: Codable {
    let count: Int
    let meanLifetime: Double
    let maxLifetime: Double
    let totalPersistence: Double

    enum CodingKeys: String, CodingKey {
        case count
        case meanLifetime = "mean_lifetime"
        case maxLifetime = "max_lifetime"
        case totalPersistence = "total_persistence"
    }
}

// MARK: - Betti Curve Data

struct BettiCurveData: Codable {
    let values: [[Double]]
    let nBins: Int
    let dimensions: [String]

    enum CodingKeys: String, CodingKey {
        case values
        case nBins = "n_bins"
        case dimensions
    }

    // Get Betti numbers for a specific homology dimension
    func bettiNumbers(for dimension: Int) -> [Double]? {
        guard dimension >= 0 && dimension < values.count else { return nil }
        return values.map { $0[dimension] }
    }
}

// MARK: - Persistence Landscape Data

struct PersistenceLandscapeData: Codable {
    let values: [[Double]]
    let shape: [Int]

    var numberOfLayers: Int {
        shape.first ?? 0
    }

    var numberOfBins: Int {
        shape.last ?? 0
    }
}

// MARK: - Point Cloud Data

struct PointCloudData: Codable {
    let points: [[Double]]
    let nPoints: Int
    let dimensions: Int

    enum CodingKeys: String, CodingKey {
        case points
        case nPoints = "n_points"
        case dimensions
    }

    // Convert to SIMD3 for RealityKit
    var simd3Points: [SIMD3<Float>] {
        points.map { point in
            SIMD3<Float>(
                Float(point[0]),
                Float(point[1]),
                Float(point[2])
            )
        }
    }
}

// MARK: - Band Metadata

struct BandMetadata: Codable {
    let summary: String?
}

// MARK: - Data Loader

@MainActor
class PersistenceDataLoader: ObservableObject {
    @Published var experiments: [PersistenceExperiment] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let dataDirectory: URL

    nonisolated init(dataDirectory: URL? = nil) {
        if let directory = dataDirectory {
            self.dataDirectory = directory
        } else {
            // Default to app bundle's root directory where JSON files are copied
            let bundle = Bundle.main
            self.dataDirectory = bundle.bundleURL
        }
    }

    func loadExperiments() {
        isLoading = true
        error = nil

        let dataDir = dataDirectory

        Task.detached {
            do {
                let fileManager = FileManager.default

                // Check if Data directory exists
                guard fileManager.fileExists(atPath: dataDir.path) else {
                    throw NSError(
                        domain: "PersistenceViewer",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Data directory not found at \(dataDir.path)"]
                    )
                }

                // Find all JSON files in Data directory
                let jsonFiles = try fileManager.contentsOfDirectory(at: dataDir, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "json" }

                var loadedExperiments: [PersistenceExperiment] = []

                print("📂 Found \(jsonFiles.count) JSON files in bundle")

                for jsonFile in jsonFiles {
                    print("📄 Loading: \(jsonFile.lastPathComponent)")
                    do {
                        let data = try Data(contentsOf: jsonFile)
                        print("  ✓ Read \(data.count) bytes")
                        let experiment = try JSONDecoder().decode(PersistenceExperiment.self, from: data)
                        print("  ✓ Decoded: \(experiment.name)")
                        loadedExperiments.append(experiment)
                    } catch {
                        print("  ✗ Failed to load experiment from \(jsonFile.lastPathComponent): \(error)")
                    }
                }

                print("📊 Loaded \(loadedExperiments.count) experiments total")

                await MainActor.run { [weak self] in
                    self?.experiments = loadedExperiments
                    self?.isLoading = false
                }

            } catch {
                await MainActor.run { [weak self] in
                    self?.error = error
                    self?.isLoading = false
                }
            }
        }
    }

    nonisolated func loadExperiment(from url: URL) throws -> PersistenceExperiment {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PersistenceExperiment.self, from: data)
    }
}
