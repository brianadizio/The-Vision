// swift-tools-version: 5.9
//
// Standalone test package for The Vision (PersistenceViewer) data models.
//
// The shipping app is a visionOS Xcode project with no test target. This
// package symlinks the real, shipped model source files (Sources/VisionModels)
// so unit tests exercise the actual code paths used by the app — not a copy.
//
// Platform is set to macOS because the models only depend on Foundation +
// SwiftUI, both of which are available on macOS. This lets `swift test` run
// natively without the visionOS simulator.
//
import PackageDescription

let package = Package(
    name: "VisionModels",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "VisionModels", targets: ["VisionModels"])
    ],
    targets: [
        .target(
            name: "VisionModels",
            path: "Sources/VisionModels"
        ),
        .testTarget(
            name: "VisionModelsTests",
            dependencies: ["VisionModels"],
            path: "Tests/VisionModelsTests"
        )
    ]
)
