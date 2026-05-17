//
//  UniversalTDAImport.swift
//  PersistenceViewer
//
//  Universal TDA data import layer — accepts persistence diagrams, point clouds,
//  and Betti curves from ANY Golden Enterprise Solution, not just Mobius Band.
//
//  Part of PROMPT-VISION-001: Generalize JSON import for all Solutions' TDA data.
//

import Foundation
import SwiftUI

// MARK: - Solution Source

/// Identifies which GES Solution produced the data
struct SolutionSource: Codable, Hashable {
    let solutionId: String       // e.g. "GES-65", "GES-078"
    let solutionName: String     // e.g. "SSEUQFT", "Pendulum Solver"
    let exportVersion: String?   // Schema version
    let exportTimestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case solutionId = "solution_id"
        case solutionName = "solution_name"
        case exportVersion = "export_version"
        case exportTimestamp = "export_timestamp"
    }
    
    /// Display-friendly name with optional ID
    var displayName: String {
        solutionName
    }
    
    /// Icon for the source Solution
    var systemImage: String {
        switch solutionName.lowercased() {
        case let s where s.contains("sonar") || s.contains("sseuqft") || s.contains("mobius"):
            return "waveform"
        case let s where s.contains("pendulum"):
            return "arrow.triangle.turn.up.right.diamond"
        case let s where s.contains("maze"):
            return "square.grid.3x3.middle.filled"
        case let s where s.contains("cipher") || s.contains("biometric"):
            return "key.fill"
        case let s where s.contains("core"):
            return "gearshape.2"
        case let s where s.contains("phi") || s.contains("sheaf"):
            return "function"
        default:
            return "cube.transparent"
        }
    }
    
    var tintColor: Color {
        switch solutionName.lowercased() {
        case let s where s.contains("sonar") || s.contains("sseuqft") || s.contains("mobius"):
            return .blue
        case let s where s.contains("pendulum"):
            return .purple
        case let s where s.contains("maze"):
            return .green
        case let s where s.contains("cipher") || s.contains("biometric"):
            return .orange
        case let s where s.contains("core"):
            return .gray
        case let s where s.contains("phi") || s.contains("sheaf"):
            return .teal
        default:
            return .indigo
        }
    }
}

// MARK: - Universal TDA Experiment

/// A universal container for TDA data from any Solution.
/// Can be decoded from either the legacy Mobius Band format or the new universal format.
struct UniversalTDAExperiment: Codable, Identifiable {
    let id: UUID
    let name: String
    let source: SolutionSource
    let description: String?
    let datasets: [TDADataset]
    let globalVisualizations: GlobalVisualizations?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case source
        case description
        case datasets
        case globalVisualizations = "global_visualizations"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        self.id = UUID()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.source = try container.decode(SolutionSource.self, forKey: .source)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.datasets = try container.decode([TDADataset].self, forKey: .datasets)
        self.globalVisualizations = try container.decodeIfPresent(GlobalVisualizations.self, forKey: .globalVisualizations)
        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
    }
    
    init(id: UUID = UUID(), name: String, source: SolutionSource, description: String? = nil,
         datasets: [TDADataset], globalVisualizations: GlobalVisualizations? = nil,
         metadata: [String: AnyCodable]? = nil) {
        self.id = id
        self.name = name
        self.source = source
        self.description = description
        self.datasets = datasets
        self.globalVisualizations = globalVisualizations
        self.metadata = metadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(datasets, forKey: .datasets)
        try container.encodeIfPresent(globalVisualizations, forKey: .globalVisualizations)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
    
    /// Total number of persistence features across all datasets
    var totalFeatureCount: Int {
        datasets.reduce(0) { $0 + ($1.persistenceDiagram?.count ?? 0) }
    }
    
    var datasetCount: Int {
        datasets.count
    }
}

// MARK: - TDA Dataset

/// A single TDA dataset — analogous to a "band" in Mobius Band format,
/// but generalized for any source. Could be a frequency band, a time window,
/// a parameter configuration, etc.
struct TDADataset: Codable, Identifiable {
    let id: UUID
    let name: String
    let groupName: String?  // e.g. "Config 1" or "Trial A" or "θ = 0.5"
    let groupId: Int?
    let datasetId: Int?
    let persistenceDiagram: [PersistenceFeature]?
    let statistics: [String: HomologyStatistics]?
    let bettiCurves: BettiCurveData?
    let persistenceLandscape: PersistenceLandscapeData?
    let pointCloud: PointCloudData?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case groupName = "group_name"
        case groupId = "group_id"
        case datasetId = "dataset_id"
        case persistenceDiagram = "persistence_diagram"
        case statistics
        case bettiCurves = "betti_curves"
        case persistenceLandscape = "persistence_landscape"
        case pointCloud = "point_cloud"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        self.id = UUID()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.groupName = try container.decodeIfPresent(String.self, forKey: .groupName)
        self.groupId = try container.decodeIfPresent(Int.self, forKey: .groupId)
        self.datasetId = try container.decodeIfPresent(Int.self, forKey: .datasetId)
        self.persistenceDiagram = try container.decodeIfPresent([PersistenceFeature].self, forKey: .persistenceDiagram)
        self.statistics = try container.decodeIfPresent([String: HomologyStatistics].self, forKey: .statistics)
        self.bettiCurves = try container.decodeIfPresent(BettiCurveData.self, forKey: .bettiCurves)
        self.persistenceLandscape = try container.decodeIfPresent(PersistenceLandscapeData.self, forKey: .persistenceLandscape)
        self.pointCloud = try container.decodeIfPresent(PointCloudData.self, forKey: .pointCloud)
        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
    }
    
    init(id: UUID = UUID(), name: String, groupName: String? = nil, groupId: Int? = nil,
         datasetId: Int? = nil, persistenceDiagram: [PersistenceFeature]? = nil,
         statistics: [String: HomologyStatistics]? = nil, bettiCurves: BettiCurveData? = nil,
         persistenceLandscape: PersistenceLandscapeData? = nil, pointCloud: PointCloudData? = nil,
         metadata: [String: AnyCodable]? = nil) {
        self.id = id
        self.name = name
        self.groupName = groupName
        self.groupId = groupId
        self.datasetId = datasetId
        self.persistenceDiagram = persistenceDiagram
        self.statistics = statistics
        self.bettiCurves = bettiCurves
        self.persistenceLandscape = persistenceLandscape
        self.pointCloud = pointCloud
        self.metadata = metadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(groupName, forKey: .groupName)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encodeIfPresent(datasetId, forKey: .datasetId)
        try container.encodeIfPresent(persistenceDiagram, forKey: .persistenceDiagram)
        try container.encodeIfPresent(statistics, forKey: .statistics)
        try container.encodeIfPresent(bettiCurves, forKey: .bettiCurves)
        try container.encodeIfPresent(persistenceLandscape, forKey: .persistenceLandscape)
        try container.encodeIfPresent(pointCloud, forKey: .pointCloud)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
    
    /// Convenience: H0/H1/H2 features
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
        name
    }
}

// MARK: - AnyCodable (lightweight type-erased Codable)

/// Minimal type-erased Codable for extensible metadata dictionaries
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Legacy Format Adapter

/// Converts the existing Mobius Band PersistenceExperiment format into the universal format
struct LegacyFormatAdapter {
    
    /// Convert a legacy PersistenceExperiment to UniversalTDAExperiment
    static func convert(_ legacy: PersistenceExperiment) -> UniversalTDAExperiment {
        let source = SolutionSource(
            solutionId: "GES-MOBIUS",
            solutionName: "Mobius Band (Sonar)",
            exportVersion: "1.0",
            exportTimestamp: legacy.exportTimestamp
        )
        
        var datasets: [TDADataset] = []
        
        for config in legacy.configurations {
            for band in config.bands {
                let dataset = TDADataset(
                    name: "Config \(config.configId) / Band \(band.bandId)",
                    groupName: "Configuration \(config.configId)",
                    groupId: config.configId,
                    datasetId: band.bandId,
                    persistenceDiagram: band.persistenceDiagram,
                    statistics: band.statistics,
                    bettiCurves: band.bettiCurves,
                    persistenceLandscape: band.persistenceLandscape,
                    pointCloud: band.pointCloud,
                    metadata: nil
                )
                datasets.append(dataset)
            }
        }
        
        return UniversalTDAExperiment(
            name: legacy.name,
            source: source,
            description: "Imported from Mobius Band sonar simulation",
            datasets: datasets,
            globalVisualizations: legacy.globalVisualizations,
            metadata: [
                "original_config_count": AnyCodable(legacy.configCount),
                "original_band_count": AnyCodable(legacy.totalBandCount),
                "source_path": AnyCodable(legacy.sourcePath)
            ]
        )
    }
}

// MARK: - Smart Data Loader

/// Unified data loader that handles both legacy and universal formats.
/// Groups experiments by source Solution for navigation.
@MainActor
class UniversalDataLoader: ObservableObject {
    @Published var experiments: [UniversalTDAExperiment] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    /// Experiments grouped by source Solution
    var groupedBySolution: [SolutionSource: [UniversalTDAExperiment]] {
        Dictionary(grouping: experiments, by: { $0.source })
    }
    
    /// Sorted solution names for display
    var sortedSolutions: [SolutionSource] {
        let grouped = groupedBySolution
        return grouped.keys.sorted { $0.solutionName < $1.solutionName }
    }
    
    private let dataDirectory: URL
    
    nonisolated init(dataDirectory: URL? = nil) {
        if let directory = dataDirectory {
            self.dataDirectory = directory
        } else {
            self.dataDirectory = Bundle.main.bundleURL
        }
    }
    
    func loadExperiments() {
        isLoading = true
        error = nil
        
        let dataDir = dataDirectory
        
        Task.detached {
            do {
                let fileManager = FileManager.default
                
                guard fileManager.fileExists(atPath: dataDir.path) else {
                    throw NSError(
                        domain: "PersistenceViewer",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Data directory not found at \(dataDir.path)"]
                    )
                }
                
                let jsonFiles = try fileManager.contentsOfDirectory(at: dataDir, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "json" }
                
                var loadedExperiments: [UniversalTDAExperiment] = []
                
                print("📂 Found \(jsonFiles.count) JSON files in bundle")
                
                for jsonFile in jsonFiles {
                    print("📄 Loading: \(jsonFile.lastPathComponent)")
                    do {
                        let data = try Data(contentsOf: jsonFile)
                        print("  ✓ Read \(data.count) bytes")
                        
                        // Try universal format first
                        if let universal = try? JSONDecoder().decode(UniversalTDAExperiment.self, from: data) {
                            print("  ✓ Decoded as universal format: \(universal.name)")
                            loadedExperiments.append(universal)
                            continue
                        }
                        
                        // Fall back to legacy Mobius Band format
                        let legacy = try JSONDecoder().decode(PersistenceExperiment.self, from: data)
                        let converted = LegacyFormatAdapter.convert(legacy)
                        print("  ✓ Decoded as legacy format, converted: \(converted.name)")
                        loadedExperiments.append(converted)
                        
                    } catch {
                        print("  ✗ Failed to load \(jsonFile.lastPathComponent): \(error)")
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
}
