//
//  EnvironmentManager.swift
//  PersistenceViewer
//
//  Manages Nature environment backgrounds for immersive topological visualization.
//  Supports multiple preset environments (placeholder gradients until real Sachuest data arrives).
//
//  When real spatial video/photos arrive from PHYS-VISION-002/004, this will:
//  - Convert equirectangular panoramas to skybox textures
//  - Support spatial audio context switching
//  - Provide environment transition animations
//

import SwiftUI
import RealityKit

// MARK: - Environment Preset

struct EnvironmentPreset: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let backgroundColor: Color
    let gradient: LinearGradient?
    let ambientLightColor: Color
    let isPlaceholder: Bool
    let source: String?  // "placeholder", "sachuest_point", "custom"
    let texturePath: String?  // equirectangular panorama path when real data available

    init(
        name: String,
        description: String,
        backgroundColor: Color,
        gradient: LinearGradient? = nil,
        ambientLightColor: Color = .white,
        isPlaceholder: Bool = true,
        source: String = "placeholder",
        texturePath: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.backgroundColor = backgroundColor
        self.gradient = gradient
        self.ambientLightColor = ambientLightColor
        self.isPlaceholder = isPlaceholder
        self.source = source
        self.texturePath = texturePath
    }
}

// MARK: - Environment Manager

@MainActor
class EnvironmentManager: ObservableObject {

    @Published var currentEnvironment: EnvironmentPreset

    init(initialEnvironment: EnvironmentPreset? = nil) {
        if let env = initialEnvironment {
            self.currentEnvironment = env
        } else {
            self.currentEnvironment = EnvironmentPreset.oceanSunset
        }
    }

    // MARK: - Preset Environments (Placeholders)

    static let oceanSunset = EnvironmentPreset(
        name: "Ocean Sunset",
        description: "Warm coastal sunset gradient matching the Coastal Design System",
        backgroundColor: .oysterPearl,
        gradient: CoastalGradients.sunset,
        ambientLightColor: .sunsetOrange,
        isPlaceholder: true,
        source: "placeholder"
    )

    static let morningMist = EnvironmentPreset(
        name: "Morning Mist",
        description: "Cool, soft gradient evoking coastal morning fog",
        backgroundColor: .beachStone,
        gradient: LinearGradient(
            colors: [.stormCloud.opacity(0.3), .oysterPearl, .shallowWater.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        ),
        ambientLightColor: .coastalWater,
        isPlaceholder: true,
        source: "placeholder"
    )

    static let nightSky = EnvironmentPreset(
        name: "Night Sky",
        description: "Deep ocean night with starlight accents",
        backgroundColor: .black,
        gradient: LinearGradient(
            colors: [.black, .deepOcean.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        ),
        ambientLightColor: .white,
        isPlaceholder: true,
        source: "placeholder"
    )

    static let coastalDay = EnvironmentPreset(
        name: "Coastal Day",
        description: "Bright, airy environment with ocean accents",
        backgroundColor: .shallowWater,
        gradient: CoastalGradients.oceanDepth,
        ambientLightColor: .white,
        isPlaceholder: true,
        source: "placeholder"
    )

    // MARK: - Environment List

    var allEnvironments: [EnvironmentPreset] {
        [
            EnvironmentPreset.oceanSunset,
            EnvironmentPreset.morningMist,
            EnvironmentPreset.nightSky,
            EnvironmentPreset.coastalDay
        ]
    }

    // MARK: - Environment Switching

    func setEnvironment(_ environment: EnvironmentPreset) {
        guard environment != currentEnvironment else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            self.currentEnvironment = environment
        }
    }

    func setEnvironmentByName(_ name: String) {
        if let env = allEnvironments.first(where: { $0.name == name }) {
            setEnvironment(env)
        }
    }

    // MARK: - Future: Real Sachuest Environment Loading

    func loadRealEnvironment(from textureURL: URL, name: String) async throws -> EnvironmentPreset {
        // When real spatial video/photo arrives, convert to equirectangular
        // and load as skybox environment
        
        let environment = EnvironmentPreset(
            name: name,
            description: "Real Sachuest Point environment captured at \(Date())",
            backgroundColor: .black,
            gradient: nil,  // Will use texture instead
            ambientLightColor: .white,
            isPlaceholder: false,
            source: "sachuest_point",
            texturePath: textureURL.path()
        )
        
        // TODO: Convert equirectangular panorama to skybox texture
        // TODO: Set up RealityKit Environment with texture
        
        return environment
    }

    // MARK: - Helpers

    func isPlaceholderEnvironment(_ env: EnvironmentPreset? = nil) -> Bool {
        let target = env ?? currentEnvironment
        return target.isPlaceholder
    }
}

// MARK: - Environment Picker View

struct EnvironmentPicker: View {
    @EnvironmentObject var environmentManager: EnvironmentManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Environment")
                .font(CoastalTypography.headline)
                .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(environmentManager.allEnvironments) { env in
                        Button {
                            environmentManager.setEnvironment(env)
                        } label: {
                            EnvironmentPresetCard(environment: env)
                                .frame(width: 140, height: 120)
                                .opacity(environmentManager.currentEnvironment.id == env.id ? 1.0 : 0.6)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            if environmentManager.isPlaceholderEnvironment() {
                Text("Placeholder environments. Replace with Sachuest Point spatial video when available.")
                    .font(CoastalTypography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding()
        .background(Color.coastalBackground)
        .cornerRadius(CoastalCorners.loose)
    }
}

struct EnvironmentPresetCard: View {
    let environment: EnvironmentPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Environment preview
            VStack {
                Spacer()
                if let gradient = environment.gradient {
                    gradient
                        .frame(height: 60)
                        .cornerRadius(CoastalCorners.tight)
                        .overlay(
                            Text("Preview")
                                .font(CoastalTypography.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        )
                } else {
                    Rectangle()
                        .fill(environment.backgroundColor)
                        .frame(height: 60)
                        .cornerRadius(CoastalCorners.tight)
                        .overlay(
                            Text("Texture")
                                .font(CoastalTypography.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        )
                }
            }

            // Environment info
            Text(environment.name)
                .font(CoastalTypography.headline)
                .foregroundStyle(.coastalPrimary)

            Text(environment.description)
                .font(CoastalTypography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

#Preview {
    EnvironmentPicker()
        .environmentObject(EnvironmentManager())
}
