//
//  PersistenceModelsTests.swift
//  VisionModelsTests
//
//  QA coverage for the pure-logic computed properties and JSON decoding of
//  The Vision's persistence-diagram data models. These exercise the real
//  shipped source (symlinked into Sources/VisionModels), with no UI/RealityKit
//  dependencies. Added by the `tests` QA pass — the app previously had zero
//  test coverage.
//
import XCTest
@testable import VisionModels

final class PersistenceModelsTests: XCTestCase {

    // MARK: - PersistenceFeature

    func testFiniteFeatureIsNotInfinite() {
        let f = PersistenceFeature(
            id: 1, birth: 0.1, death: 0.5, lifetime: 0.4,
            dimension: 1, homologyClass: "H1"
        )
        XCTAssertFalse(f.isInfinite)
        XCTAssertEqual(f.displayLifetime, "0.400")
    }

    func testInfiniteFeatureHasNoDeath() {
        let f = PersistenceFeature(
            id: 2, birth: 0.0, death: nil, lifetime: nil,
            dimension: 0, homologyClass: "H0"
        )
        XCTAssertTrue(f.isInfinite)
        XCTAssertEqual(f.displayLifetime, "∞")
    }

    // MARK: - Band homology filtering

    func testBandFiltersFeaturesByHomologyDimension() {
        let features = [
            PersistenceFeature(id: 0, birth: 0, death: 1, lifetime: 1, dimension: 0, homologyClass: "H0"),
            PersistenceFeature(id: 1, birth: 0, death: 2, lifetime: 2, dimension: 1, homologyClass: "H1"),
            PersistenceFeature(id: 2, birth: 0, death: 3, lifetime: 3, dimension: 1, homologyClass: "H1"),
            PersistenceFeature(id: 3, birth: 0, death: 4, lifetime: 4, dimension: 2, homologyClass: "H2")
        ]
        let band = Band(
            configId: 0, bandId: 7,
            persistenceDiagram: features, statistics: nil,
            bettiCurves: nil, persistenceLandscape: nil,
            pointCloud: nil, metadata: nil
        )
        XCTAssertEqual(band.h0Features.count, 1)
        XCTAssertEqual(band.h1Features.count, 2)
        XCTAssertEqual(band.h2Features.count, 1)
        XCTAssertEqual(band.displayName, "Band 7")
        XCTAssertEqual(band.id, 7)
    }

    func testBandWithNilDiagramReturnsEmptyFeatureLists() {
        let band = Band(
            configId: 0, bandId: 0,
            persistenceDiagram: nil, statistics: nil,
            bettiCurves: nil, persistenceLandscape: nil,
            pointCloud: nil, metadata: nil
        )
        XCTAssertTrue(band.h0Features.isEmpty)
        XCTAssertTrue(band.h1Features.isEmpty)
        XCTAssertTrue(band.h2Features.isEmpty)
    }

    // MARK: - BettiCurveData

    func testBettiNumbersExtractColumnForValidDimension() {
        // 3 bins x 2 homology dimensions
        let curve = BettiCurveData(
            values: [[1, 4], [2, 5], [3, 6]],
            nBins: 3,
            dimensions: ["H0", "H1"]
        )
        XCTAssertEqual(curve.bettiNumbers(for: 0), [1, 2, 3])
        XCTAssertEqual(curve.bettiNumbers(for: 1), [4, 5, 6])
    }

    func testBettiNumbersReturnsNilForOutOfRangeDimension() {
        let curve = BettiCurveData(
            values: [[1], [2]],
            nBins: 2,
            dimensions: ["H0"]
        )
        XCTAssertNil(curve.bettiNumbers(for: -1))
        XCTAssertNil(curve.bettiNumbers(for: 5))
    }

    // MARK: - JSON decoding (snake_case CodingKeys)

    func testVisualizationDataDecodesSnakeCaseKeys() throws {
        let json = """
        {
          "points": [[0.0, 1.0, 2.0], [3.0, 4.0, 5.0]],
          "n_points": 2,
          "dimensions": 3,
          "description": "test cloud"
        }
        """.data(using: .utf8)!
        let viz = try JSONDecoder().decode(VisualizationData.self, from: json)
        XCTAssertEqual(viz.nPoints, 2)
        XCTAssertEqual(viz.dimensions, 3)
        XCTAssertEqual(viz.description, "test cloud")
        // simd3Points should produce one SIMD3 per 3-element point.
        XCTAssertEqual(viz.simd3Points.count, 2)
        XCTAssertEqual(viz.simd3Points[0].x, 0.0)
        XCTAssertEqual(viz.simd3Points[1].z, 5.0)
    }

    func testManifoldEmbeddingsAvailableTypesReflectsPresentMaps() {
        let viz = VisualizationData(points: [[0, 0, 0]], nPoints: 1, dimensions: 3, description: nil)
        let embeddings = ManifoldEmbeddings(isomap: viz, diffusionMap: nil, lle: viz)
        XCTAssertEqual(embeddings.availableTypes, ["Isomap", "LLE"])
    }

    // MARK: - PersistenceExperiment aggregation

    private func makeBand(configId: Int, bandId: Int) -> Band {
        Band(
            configId: configId, bandId: bandId,
            persistenceDiagram: nil, statistics: nil,
            bettiCurves: nil, persistenceLandscape: nil,
            pointCloud: nil, metadata: nil
        )
    }

    func testExperimentAggregatesConfigAndBandCounts() {
        let configs = [
            Configuration(configId: 0, bands: [makeBand(configId: 0, bandId: 0),
                                               makeBand(configId: 0, bandId: 1)]),
            Configuration(configId: 1, bands: [makeBand(configId: 1, bandId: 0)])
        ]
        let exp = PersistenceExperiment(
            name: "demo", sourcePath: "/tmp/demo", exportTimestamp: "2026-06-06",
            globalVisualizations: nil, configurations: configs
        )
        XCTAssertEqual(exp.configCount, 2)
        XCTAssertEqual(exp.totalBandCount, 3)
        XCTAssertFalse(exp.hasGlobalVisualizations)
        // Configuration.id mirrors its configId.
        XCTAssertEqual(configs[1].id, 1)
    }

    func testEmptyExperimentHasZeroCounts() {
        let exp = PersistenceExperiment(
            name: "empty", sourcePath: "", exportTimestamp: "",
            globalVisualizations: nil, configurations: []
        )
        XCTAssertEqual(exp.configCount, 0)
        XCTAssertEqual(exp.totalBandCount, 0)
        XCTAssertFalse(exp.hasGlobalVisualizations)
    }

    func testExperimentReportsGlobalVisualizationsWhenPresent() {
        let global = GlobalVisualizations(
            globalPCA: nil, phaseSpace: nil,
            manifoldEmbeddings: nil, scattererLabels: nil
        )
        let exp = PersistenceExperiment(
            name: "viz", sourcePath: "", exportTimestamp: "",
            globalVisualizations: global, configurations: []
        )
        XCTAssertTrue(exp.hasGlobalVisualizations)
    }

    // MARK: - PersistenceLandscapeData shape

    func testLandscapeLayersAndBinsFromShape() {
        let landscape = PersistenceLandscapeData(values: [[0, 1], [2, 3]], shape: [2, 5])
        XCTAssertEqual(landscape.numberOfLayers, 2)
        XCTAssertEqual(landscape.numberOfBins, 5)
    }

    func testLandscapeWithEmptyShapeDefaultsToZero() {
        let landscape = PersistenceLandscapeData(values: [], shape: [])
        XCTAssertEqual(landscape.numberOfLayers, 0)
        XCTAssertEqual(landscape.numberOfBins, 0)
    }

    // MARK: - LabelData flattening

    func testLabelDataFlattensDoublesToInts() {
        let labels = LabelData(labels: [0.0, 1.9, 2.4, 3.0], nLabels: 4, description: nil)
        XCTAssertEqual(labels.flatLabels, [0, 1, 2, 3])
    }
}
