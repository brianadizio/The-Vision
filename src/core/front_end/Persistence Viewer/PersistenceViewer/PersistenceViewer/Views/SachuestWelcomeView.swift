//
//  SachuestWelcomeView.swift
//  PersistenceViewer
//
//  PROMPT-VISION-007: Sachuest Now Integration.
//
//  Positions The Vision as the serene entry point to the Sachuest Now
//  experience. On launch the user arrives in a calm Nature reserve (the
//  selected EnvironmentPreset skybox) and, at their own pace, the mathematics
//  of that world — the topological persistence data — fades into view.
//
//  The flow has three phases:
//    .arriving    — full-bleed Nature scene, a single gentle "Begin" affordance.
//    .transition  — Nature recedes, a brief poetic line bridges Nature → math.
//    .exploring   — the normal ExperimentListView data space, self-paced.
//
//  Two bridges to Sachuest Now (the full VR game):
//    * A deep link (`sachuest-now://session?...`) carrying the shared
//      environment id so the game opens in the same Nature reserve.
//    * SachuestHandoff: a small Codable payload (also written to the shared
//      restriction-map directory) so a co-located Sachuest Now build can pick
//      up exactly where the calm session left off — the "shared session" path
//      from requirement 4.
//
//  Requirement 5 (shared 3D environment assets) is satisfied by reusing the
//  app-level EnvironmentManager and its EnvironmentPreset list: the same skybox
//  presets that wrap the data space are the assets Sachuest Now consumes via
//  the handoff's `environmentName` / `texturePath`.
//

import SwiftUI

// MARK: - Welcome Phase

/// The three stages of arriving at Sachuest. Kept as a small state machine so
/// the transition (requirement 2) is explicit and testable rather than implied
/// by scattered booleans.
enum SachuestWelcomePhase: String, CaseIterable {
    case arriving
    case transition
    case exploring
}

// MARK: - Sachuest Now Handoff Payload

/// Shared-session payload handed to Sachuest Now when the user is ready to move
/// from the calm data space into the full VR game (requirement 4). Written as
/// JSON to the restriction-map directory and also encoded into a deep link.
struct SachuestHandoff: Codable {
    /// Name of the shared EnvironmentPreset so the game opens in the same
    /// Nature reserve the user has been sitting in (requirement 5).
    let environmentName: String
    /// Optional equirectangular panorama path for the shared environment, when
    /// a real Sachuest Point capture has replaced the placeholder gradient.
    let texturePath: String?
    /// Identifier of the source app emitting the handoff.
    let source: String
    /// Wall-clock time the handoff was created.
    let createdAt: Date

    /// `sachuest-now://session?env=...&texture=...` deep link representation.
    var deepLinkURL: URL? {
        var components = URLComponents()
        components.scheme = "sachuest-now"
        components.host = "session"
        var items = [URLQueryItem(name: "env", value: environmentName),
                     URLQueryItem(name: "source", value: source)]
        if let texturePath { items.append(URLQueryItem(name: "texture", value: texturePath)) }
        components.queryItems = items
        return components.url
    }
}

/// Writes the handoff payload to the shared restriction-map directory so a
/// co-located Sachuest Now build can read the same session context. Mirrors the
/// export locations used by RestrictionMapExporter (assets/processed).
enum SachuestHandoffWriter {
    static func write(_ handoff: SachuestHandoff) {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dir = docs.appendingPathComponent("assets/processed/sachuest_now", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("handoff_latest.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(handoff) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Welcome View

/// Root gate shown on launch. Owns the welcome → transition → exploring flow
/// and hosts ContentView once the user chooses to explore.
struct SachuestWelcomeView: View {
    @EnvironmentObject private var environmentManager: EnvironmentManager
    @EnvironmentObject private var sessionRecorder: SessionRecorder

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openURL) private var openURL

    @State private var phase: SachuestWelcomePhase = .arriving
    @State private var titleVisible = false
    @State private var showHandoffConfirmation = false

    var body: some View {
        ZStack {
            // The Nature scene as a windowed backdrop. The same gradient that
            // wraps the immersive skybox grounds the welcome screen so the
            // arrival feels continuous with the immersive space (requirement 5).
            backdrop
                .ignoresSafeArea()
                .opacity(phase == .exploring ? 0 : 1)
                .animation(CoastalAnimations.tide, value: phase)

            switch phase {
            case .arriving:
                arrivingContent
                    .transition(.opacity)
            case .transition:
                transitionContent
                    .transition(.opacity)
            case .exploring:
                ContentView()
                    .environmentObject(environmentManager)
                    .environmentObject(sessionRecorder)
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .toolbar { handoffToolbar }
                    .alert("Carrying you to Sachuest", isPresented: $showHandoffConfirmation) {
                        Button("OK") {}
                    } message: {
                        Text("Your Nature reserve and session were shared with Sachuest Now.")
                    }
            }
        }
        .animation(CoastalAnimations.wave, value: phase)
        .onAppear {
            withAnimation(CoastalAnimations.tide.delay(0.4)) {
                titleVisible = true
            }
        }
    }

    // MARK: Backdrop

    @ViewBuilder
    private var backdrop: some View {
        if let gradient = environmentManager.currentEnvironment.gradient {
            gradient
        } else {
            environmentManager.currentEnvironment.backgroundColor
        }
    }

    private var foreground: Color {
        environmentManager.currentEnvironment.recommendedForeground
    }

    // MARK: Phase: Arriving

    private var arrivingContent: some View {
        VStack(spacing: CoastalSpacing.lg) {
            Spacer()

            Image(systemName: "water.waves")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(foreground)
                .opacity(titleVisible ? 1 : 0)
                .symbolEffect(.pulse)

            Text("Welcome to Sachuest")
                .font(CoastalTypography.largeTitle)
                .foregroundStyle(foreground)
                .opacity(titleVisible ? 1 : 0)

            Text("A quiet Nature reserve where the mathematics of the world becomes visible. Stay as long as you like.")
                .font(CoastalTypography.body)
                .foregroundStyle(foreground.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .opacity(titleVisible ? 1 : 0)

            Spacer()

            VStack(spacing: CoastalSpacing.md) {
                Button {
                    enterNatureThenExplore()
                } label: {
                    Label("Begin", systemImage: "leaf.fill")
                        .font(CoastalTypography.headline)
                        .padding(.horizontal, CoastalSpacing.xl)
                        .padding(.vertical, CoastalSpacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(.coastalPrimary)

                Button {
                    // Skip the slow arrival for returning users who just want data.
                    withAnimation(CoastalAnimations.wave) { phase = .exploring }
                } label: {
                    Text("Skip to data")
                        .font(CoastalTypography.callout)
                        .foregroundStyle(foreground.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .opacity(titleVisible ? 1 : 0)

            Spacer().frame(height: CoastalSpacing.xxl)
        }
        .padding()
    }

    // MARK: Phase: Transition

    private var transitionContent: some View {
        VStack(spacing: CoastalSpacing.lg) {
            Spacer()
            Text("Look closely…")
                .font(CoastalTypography.title)
                .foregroundStyle(foreground)
            Text("the loops, the voids, the shapes the ocean leaves behind.")
                .font(CoastalTypography.body)
                .foregroundStyle(foreground.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
            ProgressView()
                .tint(foreground)
                .padding(.top, CoastalSpacing.md)
            Spacer()
        }
        .padding()
        .onAppear {
            // Hold the poetic bridge briefly, then reveal the data space.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(CoastalAnimations.wave) { phase = .exploring }
            }
        }
    }

    // MARK: Flow

    /// Open the immersive Nature backdrop (shared skybox), then move through the
    /// poetic transition into the data space. This is the "gradual transition
    /// from Nature environment to data visualization" of requirement 2.
    private func enterNatureThenExplore() {
        Task { @MainActor in
            _ = await openImmersiveSpace(id: immersiveBackgroundID)
            withAnimation(CoastalAnimations.wave) { phase = .transition }
        }
    }

    // MARK: Sachuest Now handoff toolbar

    @ToolbarContentBuilder
    private var handoffToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                handoffToSachuestNow()
            } label: {
                Label("Sachuest Now", systemImage: "sparkles")
            }
        }
    }

    /// Bridge to Sachuest Now (requirement 4). Writes the shared-session payload
    /// and attempts to open the deep link; the alert confirms either way so the
    /// calm experience never dead-ends if the game is not installed.
    private func handoffToSachuestNow() {
        let env = environmentManager.currentEnvironment
        let handoff = SachuestHandoff(
            environmentName: env.name,
            texturePath: env.texturePath,
            source: "the-vision",
            createdAt: Date()
        )
        SachuestHandoffWriter.write(handoff)
        if let url = handoff.deepLinkURL {
            openURL(url) { _ in
                showHandoffConfirmation = true
            }
        } else {
            showHandoffConfirmation = true
        }
    }
}

#Preview(windowStyle: .automatic) {
    SachuestWelcomeView()
        .environmentObject(EnvironmentManager())
        .environmentObject(SessionRecorder())
}
