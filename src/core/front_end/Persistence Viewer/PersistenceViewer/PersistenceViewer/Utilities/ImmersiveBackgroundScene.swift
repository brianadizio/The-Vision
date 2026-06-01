//
//  ImmersiveBackgroundScene.swift
//  PersistenceViewer
//
//  Renders the current EnvironmentPreset as an immersive skybox surrounding the
//  user inside a Vision Pro ImmersiveSpace.
//
//  Strategy
//  --------
//  We build a large inverted sphere (~50 m radius) and apply one of two materials:
//    * Placeholder mode (default) — UnlitMaterial whose baseColor is the preset's
//      backgroundColor; gradients are baked into a procedurally generated
//      equirectangular CGImage so the SwiftUI LinearGradient is preserved
//      as a real texture wrapping the sphere.
//    * Texture mode — when `EnvironmentPreset.texturePath` points at a real
//      equirectangular panorama (eventually a Sachuest Point spatial photo),
//      we load it via TextureResource and apply it the same way.
//
//  The sphere normals are flipped (negative scale on X) so the texture is visible
//  from the inside.
//
//  Future work
//  -----------
//  When PHYS-VISION-002 / PHYS-VISION-004 land we will:
//    * Convert spatial video frames to equirectangular projections per-frame and
//      stream them as a VideoMaterial.
//    * Drop the procedural gradient bake in favour of HDR EXR panoramas with
//      ImageBasedLight for accurate environment lighting on the data entities.
//

import SwiftUI
import RealityKit
import CoreGraphics

// MARK: - Scene Identifier

/// String ID for the immersive backdrop scene; referenced by
/// `openImmersiveSpace(id:)` and the @main App's `ImmersiveSpace(id:)`.
let immersiveBackgroundID = "ImmersiveBackground"

// MARK: - Immersive Backdrop View

struct ImmersiveBackgroundView: View {
    @EnvironmentObject var environmentManager: EnvironmentManager

    var body: some View {
        RealityView { content in
            // Initial population on first appearance
            await rebuildSkybox(in: content,
                                preset: environmentManager.currentEnvironment)
        } update: { content in
            // Re-render when the user picks a new preset.
            Task { @MainActor in
                await rebuildSkybox(in: content,
                                    preset: environmentManager.currentEnvironment)
            }
        }
    }

    // MARK: Sphere construction

    /// Tear down and rebuild the inverted sphere so the material reflects the
    /// currently-selected preset.
    @MainActor
    private func rebuildSkybox(in content: RealityViewContent,
                               preset: EnvironmentPreset) async {
        // Remove any previously-mounted skybox entity so we don't stack them.
        for entity in content.entities where entity.name == "skybox" {
            content.remove(entity)
        }

        let skybox = await makeSkyboxEntity(for: preset)
        content.add(skybox)
    }

    @MainActor
    private func makeSkyboxEntity(for preset: EnvironmentPreset) async -> Entity {
        let sphere = MeshResource.generateSphere(radius: 50)

        var material: Material
        if let path = preset.texturePath,
           let texture = try? await loadEquirectangularTexture(from: path) {
            var unlit = UnlitMaterial()
            unlit.color = .init(texture: .init(texture))
            material = unlit
        } else {
            var unlit = UnlitMaterial()
            if let baked = BakedSkyboxRenderer.bakeGradient(preset: preset),
               let texture = try? TextureResource(image: baked,
                                                  options: .init(semantic: .color)) {
                unlit.color = .init(texture: .init(texture))
            } else {
                unlit.color = .init(tint: UIColor(preset.backgroundColor))
            }
            material = unlit
        }

        let entity = ModelEntity(mesh: sphere, materials: [material])
        entity.name = "skybox"
        // Flip the sphere inside-out so the texture is visible from within.
        entity.scale = SIMD3<Float>(-1, 1, 1)
        return entity
    }

    /// Load an external equirectangular panorama from disk (future: Sachuest data).
    private func loadEquirectangularTexture(from path: String) async throws -> TextureResource {
        let url = URL(fileURLWithPath: path)
        return try await TextureResource(contentsOf: url,
                                         options: .init(semantic: .color))
    }
}

// MARK: - Procedural Gradient Texture Baker

/// Bakes a SwiftUI LinearGradient (defined on the preset) into a 2048×1024
/// equirectangular CGImage suitable for wrapping a sphere. Runs entirely on
/// CPU so we do not need GPU compositing for the placeholder phase.
enum BakedSkyboxRenderer {
    /// Width/height of the equirectangular bake. 2:1 ratio is required for
    /// proper sphere wrapping; 2048×1024 is a sane visual quality vs. memory
    /// tradeoff for placeholder skyboxes.
    static let width = 2048
    static let height = 1024

    static func bakeGradient(preset: EnvironmentPreset) -> CGImage? {
        // Resolve the preset's gradient into a flat stop list. SwiftUI's
        // LinearGradient does not expose its stops publicly, so we keep a
        // parallel set of stop colors in `EnvironmentPreset.gradientStops`.
        let stops = preset.gradientStops ?? [preset.backgroundColor]

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return nil
        }

        // Build a CGGradient from the preset stops.
        let cgColors = stops.map { UIColor($0).cgColor } as CFArray
        let locations: [CGFloat] = stops.enumerated().map { idx, _ in
            stops.count == 1 ? 0 : CGFloat(idx) / CGFloat(stops.count - 1)
        }
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: cgColors,
                                        locations: locations) else {
            return nil
        }

        // Draw a vertical gradient (top → bottom). Equirectangular sphere
        // wrapping makes the top of the image land at the user's "sky" and
        // the bottom at the "ground", giving a natural horizon effect.
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: CGFloat(height)),
                                   end: CGPoint(x: 0, y: 0),
                                   options: [])

        return context.makeImage()
    }
}

// MARK: - EnvironmentPreset gradient resolution

extension EnvironmentPreset {
    /// Per-preset color stops used by the skybox baker. We store these
    /// alongside the SwiftUI gradient because LinearGradient itself does not
    /// expose its stop list.
    ///
    /// The mapping is by preset name (the canonical identifier across the
    /// preset list); presets without an entry fall back to a single-color
    /// background bake.
    var gradientStops: [Color]? {
        switch name {
        case "Ocean Sunset":
            return [.sunsetOrange, .sunsetCoral, .goldenPeach, .oysterPearl]
        case "Morning Mist":
            return [.stormCloud.opacity(0.3), .oysterPearl, .shallowWater.opacity(0.2)]
        case "Night Sky":
            return [.black, .deepOcean.opacity(0.6), .black]
        case "Coastal Day":
            return [.deepOcean, .midOcean, .coastalWater, .shallowWater]
        default:
            return nil
        }
    }

    /// Recommend a foreground color (text / UI chrome) that will remain
    /// readable when rendered on top of this environment. Computed from
    /// average luminance of the gradient stops; defaults to white for
    /// dark backgrounds and `coastalPrimary` for light ones.
    var recommendedForeground: Color {
        let stops = gradientStops ?? [backgroundColor]
        let lum = stops.map(Self.relativeLuminance).reduce(0, +) / Double(stops.count)
        return lum < 0.45 ? .white : .coastalPrimary
    }

    /// Relative luminance of a SwiftUI Color (Rec. 709 approximation).
    /// Note: Color → UIColor → CGColor → RGB components is the only reliable
    /// way to extract numeric channels from a SwiftUI Color on visionOS.
    private static func relativeLuminance(_ color: Color) -> Double {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Rec. 709 luma coefficients.
        return Double(0.2126 * r + 0.7152 * g + 0.0722 * b)
    }
}
