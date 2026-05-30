//
//  SpatialAudioEngine.swift
//  PersistenceViewer
//
//  Shepard tone sonification of topological Betti curves.
//  Maps H0/H1/H2 Betti numbers to layered pitch registers via circular
//  pitch illusion (Shepard tones). Higher Betti numbers → louder tone at
//  that register. Persistent features → sustained amplitude. Birth events
//  → attack transients, death events → release tails.
//
//  Spatial: per-feature point sources are placed at their 3D location via
//  AVAudioEnvironmentNode so the user perceives them coming from the
//  corresponding region of the visualisation. An ambient ocean wave wash
//  is synthesised in the background (Data Y Sheaf connection).
//

import AVFoundation
import Foundation
import Observation
import simd

@Observable
final class SpatialAudioEngine {

    // MARK: - Observable State

    var isActive: Bool = false
    var volume: Float = 0.65
    /// When true, the ambient ocean wash plays underneath sonifications.
    var ambientEnabled: Bool = true

    // MARK: - Private

    private let engine = AVAudioEngine()
    /// One player node per Betti dimension (0=H0, 1=H1, 2=H2). Routed to mainMixer.
    private var players: [Int: AVAudioPlayerNode] = [:]
    /// Dedicated player for spatially positioned, per-feature point sources.
    /// Routed through `environmentNode` for HRTF spatialisation.
    private var spatialPlayer: AVAudioPlayerNode?
    /// Background ambient (ocean wave wash) — routed through the environment node.
    private var ambientPlayer: AVAudioPlayerNode?
    /// 3D environment for HRTF / spatial audio.
    private var environmentNode: AVAudioEnvironmentNode?
    private let sampleRate: Double = 44100.0

    /// Base frequencies per homology dimension.
    /// H0 (connected components) → low register C3
    /// H1 (loops)               → mid register C4
    /// H2 (voids)               → high register C5
    private let baseFreq: [Int: Double] = [
        0: 130.813,   // C3
        1: 261.626,   // C4
        2: 523.251    // C5
    ]

    // MARK: - Init

    init() {
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        let mixer = engine.mainMixerNode

        // Per-dimension non-spatial players (used by sweep / threshold).
        for dim in 0..<3 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            if let fmt = stereoFormat() {
                engine.connect(player, to: mixer, format: fmt)
            }
            players[dim] = player
        }

        // Environment node for HRTF spatial audio.
        let env = AVAudioEnvironmentNode()
        env.renderingAlgorithm = .HRTF
        env.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        env.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
        env.distanceAttenuationParameters.distanceAttenuationModel = .inverse
        env.distanceAttenuationParameters.referenceDistance = 0.3
        env.distanceAttenuationParameters.maximumDistance = 5.0
        env.distanceAttenuationParameters.rolloffFactor = 1.2
        engine.attach(env)
        if let envFmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) {
            engine.connect(env, to: mixer, format: envFmt)
        }
        environmentNode = env

        // Spatial point-source player (mono input → HRTF).
        let spatial = AVAudioPlayerNode()
        spatial.renderingAlgorithm = .HRTF
        engine.attach(spatial)
        if let monoFmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            engine.connect(spatial, to: env, format: monoFmt)
        }
        spatialPlayer = spatial

        // Ambient ocean wash (stereo, positioned slightly behind the listener).
        let ambient = AVAudioPlayerNode()
        ambient.renderingAlgorithm = .HRTF
        ambient.position = AVAudio3DPoint(x: 0, y: 0.2, z: 2.0)
        engine.attach(ambient)
        if let monoFmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            engine.connect(ambient, to: env, format: monoFmt)
        }
        ambientPlayer = ambient

        do {
            try engine.start()
        } catch {
            // Audio unavailable (simulator without audio hardware is fine)
        }
    }

    private func stereoFormat() -> AVAudioFormat? {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
    }

    // MARK: - Public API

    /// Play a short Shepard chord representing a single threshold snapshot.
    /// - Parameters:
    ///   - bettiValues: [h0, h1, h2] at the selected threshold index
    ///   - maxBetti: maximum Betti value across all thresholds (for normalisation)
    func sonifyThreshold(bettiValues: [Double], maxBetti: Double) {
        guard isActive, engine.isRunning else { return }
        let normMax = max(maxBetti, 1.0)

        for dim in 0..<3 {
            guard let player = players[dim] else { continue }
            let raw = dim < bettiValues.count ? bettiValues[dim] : 0.0
            let amp = Float(raw / normMax) * volume

            if amp > 0.02 {
                if let buf = makeShepardBuffer(dimension: dim, amplitude: amp, duration: 0.35) {
                    player.stop()
                    player.scheduleBuffer(buf, at: nil, options: .interrupts)
                    player.play()
                }
            } else {
                player.stop()
            }
        }
    }

    /// Sweep through all thresholds in sequence, playing brief notes.
    /// Runs on a background thread; safe to call from the main thread.
    func sonifySweep(bettiCurves: BettiCurveData) {
        guard isActive, engine.isRunning else { return }

        let maxBetti = bettiCurves.values.flatMap { $0 }.max() ?? 1.0
        let normMax = max(maxBetti, 1.0)
        let binDuration: Double = 0.04    // 40 ms per bin → ~4 s for 100 bins
        let noteDuration: Double = 0.05

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            for values in bettiCurves.values {
                guard self.isActive else { break }
                for dim in 0..<3 {
                    guard let player = self.players[dim] else { continue }
                    let raw = dim < values.count ? values[dim] : 0.0
                    let amp = Float(raw / normMax) * self.volume * 0.6
                    if amp > 0.02,
                       let buf = self.makeShepardBuffer(
                        dimension: dim, amplitude: amp, duration: noteDuration) {
                        player.scheduleBuffer(buf, at: nil, options: .interrupts)
                        if !player.isPlaying { player.play() }
                    }
                }
                Thread.sleep(forTimeInterval: binDuration)
            }
        }
    }

    func stopAll() {
        players.values.forEach { $0.stop() }
        spatialPlayer?.stop()
        ambientPlayer?.stop()
    }

    // MARK: - Spatial Per-Feature Sonification

    /// Sonify a single persistence feature at a 3D location.
    ///
    /// The pitch register is chosen by `dimension` (H0/H1/H2). `lifetime`
    /// controls duration (long-lived → sustained tone). `amplitudeScale` is
    /// a 0–1 importance weight (typically `lifetime / maxLifetime`).
    /// The tone is rendered through `AVAudioEnvironmentNode` so the
    /// listener perceives it arriving from `position` in 3D space.
    ///
    /// - Parameters:
    ///   - position: World-space SIMD3<Float> (matches the RealityKit point cloud).
    ///   - dimension: Homology dimension 0/1/2.
    ///   - lifetime: Persistence (death − birth). Drives sustain length.
    ///   - amplitudeScale: 0…1 relative loudness.
    func sonifyFeature(at position: SIMD3<Float>,
                       dimension: Int,
                       lifetime: Double,
                       amplitudeScale: Float) {
        guard isActive, engine.isRunning,
              let player = spatialPlayer else { return }

        // Place the source in 3D space (AVAudio uses left-handed, right-up).
        player.position = AVAudio3DPoint(x: position.x,
                                         y: position.y,
                                         z: position.z)

        // Duration: 0.18s baseline + lifetime-scaled sustain up to 1.2s.
        let sustain = min(max(lifetime, 0.0), 1.0) * 1.0
        let duration = 0.18 + sustain
        let amp = max(0.05, min(amplitudeScale, 1.0)) * volume

        if let buf = makeShepardMonoBuffer(dimension: dimension,
                                           amplitude: amp,
                                           duration: duration) {
            player.scheduleBuffer(buf, at: nil, options: .interrupts)
            if !player.isPlaying { player.play() }
        }
    }

    /// Convenience: sonify a sequence of birth/death events for a band.
    /// Birth → attack transient (short bright burst). Death → release tail.
    /// Features are processed in birth-time order so the sweep tracks the
    /// filtration parameter as it grows.
    func sonifyBirthDeathSequence(features: [(birth: Double,
                                              death: Double?,
                                              dimension: Int,
                                              position: SIMD3<Float>)],
                                  maxLifetime: Double) {
        guard isActive, engine.isRunning else { return }
        let sorted = features.sorted { $0.birth < $1.birth }
        let normMax = max(maxLifetime, 1e-6)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let startWall = Date()
            // Compress time: 4s window across the full filtration.
            let totalSpan = (sorted.last?.death ?? sorted.last?.birth ?? 1.0) -
                            (sorted.first?.birth ?? 0.0)
            let compression = totalSpan > 0 ? 4.0 / totalSpan : 1.0

            for feat in sorted {
                guard self.isActive else { break }
                let lifetime = (feat.death ?? feat.birth) - feat.birth
                let amp = Float(min(lifetime / normMax, 1.0))
                let scheduledOffset = feat.birth * compression
                let waited = Date().timeIntervalSince(startWall)
                let sleepFor = max(0.0, scheduledOffset - waited)
                if sleepFor > 0 { Thread.sleep(forTimeInterval: sleepFor) }
                DispatchQueue.main.async {
                    self.sonifyFeature(at: feat.position,
                                       dimension: feat.dimension,
                                       lifetime: lifetime,
                                       amplitudeScale: amp)
                }
            }
        }
    }

    /// Update the listener's head position (e.g. when the camera/user moves).
    func updateListener(position: SIMD3<Float>,
                        yaw: Float = 0,
                        pitch: Float = 0,
                        roll: Float = 0) {
        environmentNode?.listenerPosition = AVAudio3DPoint(x: position.x,
                                                           y: position.y,
                                                           z: position.z)
        environmentNode?.listenerAngularOrientation =
            AVAudio3DAngularOrientation(yaw: yaw, pitch: pitch, roll: roll)
    }

    // MARK: - Ambient Ocean Wash

    /// Start a looping ocean-wave ambient track (procedural pink-noise wash
    /// shaped by a slow 0.18 Hz amplitude envelope). Connects The Vision
    /// to Sachuest Point's coastal soundscape until real field recordings
    /// land via PHYS-VISION-003.
    func startAmbient() {
        guard ambientEnabled, engine.isRunning, let player = ambientPlayer else { return }
        // 8 second loop, looped via .loops scheduling option.
        guard let buffer = makeOceanAmbientBuffer(duration: 8.0,
                                                  amplitude: 0.20 * volume) else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
    }

    func stopAmbient() {
        ambientPlayer?.stop()
    }

    // MARK: - Synthesis Helpers (mono buffers for spatial routing)

    private func makeShepardMonoBuffer(dimension: Int,
                                       amplitude: Float,
                                       duration: Double) -> AVAudioPCMBuffer? {
        guard let base = baseFreq[dimension],
              let monoFmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate,
                                          channels: 1) else { return nil }

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: monoFmt,
                                            frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let ch = buffer.floatChannelData?[0] else { return nil }

        let nOctaves = 7
        let logCenter: Double = log2(base) + 2.0
        let sigma: Double = 1.5

        var weights: [Float] = []
        var freqs: [Double] = []
        for k in 0..<nOctaves {
            let f = base * pow(2.0, Double(k))
            let logRatio = log2(f) - logCenter
            let w = Float(exp(-(logRatio * logRatio) / (2.0 * sigma * sigma)))
            weights.append(w)
            freqs.append(f)
        }
        let weightSum = weights.reduce(0, +)
        let normWeights = weightSum > 0 ? weights.map { $0 / weightSum } : weights

        let nFrames = Int(frameCount)
        let attackFrames = Int(0.012 * sampleRate)
        let releaseFrames = Int(0.12 * sampleRate)

        for i in 0..<nFrames {
            let t = Double(i) / sampleRate
            let env: Float
            if i < attackFrames {
                env = Float(i) / Float(max(attackFrames, 1))
            } else if i >= nFrames - releaseFrames {
                env = Float(nFrames - i) / Float(max(releaseFrames, 1))
            } else {
                env = 1.0
            }
            var sample: Float = 0.0
            for k in 0..<nOctaves {
                sample += normWeights[k] * sin(Float(2.0 * .pi * freqs[k] * t))
            }
            ch[i] = sample * amplitude * env
        }

        return buffer
    }

    /// Procedural ocean wash: filtered pink-noise with a slow ~0.18 Hz LFO
    /// amplitude envelope evoking distant surf. Mono so it can be spatialised.
    private func makeOceanAmbientBuffer(duration: Double,
                                        amplitude: Float) -> AVAudioPCMBuffer? {
        guard let monoFmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate,
                                          channels: 1) else { return nil }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: monoFmt,
                                            frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let ch = buffer.floatChannelData?[0] else { return nil }

        let nFrames = Int(frameCount)
        // Voss-McCartney pink noise approximation via summed octave-stage rngs.
        var rng = SystemRandomNumberGenerator()
        var stages: [Float] = Array(repeating: 0, count: 7)
        var stageCounter: Int = 0
        var lpState: Float = 0

        for i in 0..<nFrames {
            stageCounter += 1
            for k in 0..<stages.count where (stageCounter & (1 << k)) == 0 {
                let r = Float.random(in: -1...1, using: &rng)
                stages[k] = r
                break
            }
            let pink = stages.reduce(0, +) / Float(stages.count)

            // Low-pass to push energy below ~600 Hz (surf rumble).
            let alpha: Float = 0.06
            lpState = lpState + alpha * (pink - lpState)

            // Slow LFO envelope ~0.18 Hz, plus a faster 1.3 Hz ripple for waves.
            let t = Double(i) / sampleRate
            let slow = 0.5 + 0.5 * Float(sin(2.0 * .pi * 0.18 * t))
            let ripple = 0.85 + 0.15 * Float(sin(2.0 * .pi * 1.3 * t + 0.7))
            let env = slow * ripple

            ch[i] = lpState * env * amplitude
        }

        return buffer
    }

    // MARK: - Shepard Tone Synthesis

    /// Synthesise a Shepard tone PCM buffer.
    ///
    /// A Shepard tone stacks octave-spaced sinusoidal partials whose amplitudes
    /// follow a log-frequency Gaussian bell curve, producing the circular-pitch
    /// illusion. The result has an ocean-like, timeless quality appropriate for
    /// immersive topological visualisation.
    private func makeShepardBuffer(
        dimension: Int,
        amplitude: Float,
        duration: Double
    ) -> AVAudioPCMBuffer? {
        guard let base = baseFreq[dimension],
              let format = stereoFormat() else { return nil }

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let chL = buffer.floatChannelData?[0],
              let chR = buffer.floatChannelData?[1] else { return nil }

        let nOctaves = 7
        // Bell-curve centre in log2 space (two octaves above base)
        let logCenter: Double = log2(base) + 2.0
        let sigma: Double = 1.5   // width of the Gaussian in octave units

        let nFrames = Int(frameCount)
        let attackFrames = Int(0.012 * sampleRate)
        let releaseFrames = Int(0.07 * sampleRate)

        // Precompute per-partial weights
        var weights: [Float] = []
        var freqs: [Double] = []
        for k in 0..<nOctaves {
            let f = base * pow(2.0, Double(k))
            let logRatio = log2(f) - logCenter
            let w = Float(exp(-(logRatio * logRatio) / (2.0 * sigma * sigma)))
            weights.append(w)
            freqs.append(f)
        }
        let weightSum = weights.reduce(0, +)
        let normWeights = weightSum > 0 ? weights.map { $0 / weightSum } : weights

        for i in 0..<nFrames {
            let t = Double(i) / sampleRate

            // ADSR envelope
            let env: Float
            if i < attackFrames {
                env = Float(i) / Float(max(attackFrames, 1))
            } else if i >= nFrames - releaseFrames {
                env = Float(nFrames - i) / Float(max(releaseFrames, 1))
            } else {
                env = 1.0
            }

            var sample: Float = 0.0
            for k in 0..<nOctaves {
                sample += normWeights[k] * sin(Float(2.0 * .pi * freqs[k] * t))
            }

            let out = sample * amplitude * env
            chL[i] = out
            chR[i] = out
        }

        return buffer
    }
}
