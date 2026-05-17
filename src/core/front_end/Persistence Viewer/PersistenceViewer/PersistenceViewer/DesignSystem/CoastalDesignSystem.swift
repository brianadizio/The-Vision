//
//  CoastalDesignSystem.swift
//  PersistenceViewer
//
//  Coastal-inspired design system for topological data visualization
//  Colors extracted from natural coastal environments
//

import SwiftUI

// MARK: - Coastal Color Palette

extension Color {
    // MARK: Primary Ocean Blues

    /// Deep ocean blue - primary brand color
    static let deepOcean = Color(red: 0x1A / 255.0, green: 0x4D / 255.0, blue: 0x6F / 255.0)

    /// Mid-ocean blue
    static let midOcean = Color(red: 0x2D / 255.0, green: 0x6A / 255.0, blue: 0x8E / 255.0)

    /// Coastal water - lighter blue
    static let coastalWater = Color(red: 0x7F / 255.0, green: 0xB3 / 255.0, blue: 0xD5 / 255.0)

    /// Shallow water - lightest blue
    static let shallowWater = Color(red: 0xA8 / 255.0, green: 0xD5 / 255.0, blue: 0xE8 / 255.0)

    // MARK: Coastal Greens

    /// Sea grass yellow-green
    static let seaGrass = Color(red: 0xB8 / 255.0, green: 0xC7 / 255.0, blue: 0x7E / 255.0)

    /// Sage green
    static let sageGreen = Color(red: 0x8A / 255.0, green: 0x9A / 255.0, blue: 0x7B / 255.0)

    /// Coastal vegetation - deeper green
    static let coastalVegetation = Color(red: 0x5A / 255.0, green: 0x6F / 255.0, blue: 0x4B / 255.0)

    // MARK: Warm Accents

    /// Pink thistle - vibrant accent
    static let pinkThistle = Color(red: 0xE8 / 255.0, green: 0x5D / 255.0, blue: 0x9F / 255.0)

    /// Sunset coral
    static let sunsetCoral = Color(red: 0xFF / 255.0, green: 0xB8 / 255.0, blue: 0x9D / 255.0)

    /// Golden hour peach
    static let goldenPeach = Color(red: 0xFF / 255.0, green: 0xD7 / 255.0, blue: 0xA8 / 255.0)

    /// Sunset orange
    static let sunsetOrange = Color(red: 0xFF / 255.0, green: 0x9D / 255.0, blue: 0x6B / 255.0)

    // MARK: Neutrals

    /// Oyster pearl - light neutral
    static let oysterPearl = Color(red: 0xF5 / 255.0, green: 0xF3 / 255.0, blue: 0xED / 255.0)

    /// Beach stone - medium neutral
    static let beachStone = Color(red: 0xD4 / 255.0, green: 0xCF / 255.0, blue: 0xC4 / 255.0)

    /// Weathered rock - darker neutral
    static let weatheredRock = Color(red: 0x8A / 255.0, green: 0x87 / 255.0, blue: 0x7F / 255.0)

    /// Storm cloud - dark neutral
    static let stormCloud = Color(red: 0x4A / 255.0, green: 0x49 / 255.0, blue: 0x4D / 255.0)

    // MARK: Semantic Colors (for consistent UI usage)

    /// Primary action color
    static let coastalPrimary = deepOcean

    /// Secondary action color
    static let coastalSecondary = midOcean

    /// Accent for highlights
    static let coastalAccent = pinkThistle

    /// Success/positive state
    static let coastalSuccess = seaGrass

    /// Warning state
    static let coastalWarning = sunsetOrange

    /// Background tint
    static let coastalBackground = oysterPearl

    /// Surface color (cards, panels)
    static let coastalSurface = Color.white
}

// MARK: - Homology Dimension Colors

extension Color {
    /// H0 (connected components) - Deep ocean blue
    static let h0Color = Color.deepOcean

    /// H1 (loops/cycles) - Sea grass green
    static let h1Color = Color.seaGrass

    /// H2 (voids/cavities) - Pink thistle
    static let h2Color = Color.pinkThistle
}

// MARK: - Gradient Definitions

struct CoastalGradients {
    /// Ocean depth gradient (deep to shallow)
    static let oceanDepth = LinearGradient(
        colors: [.deepOcean, .midOcean, .coastalWater, .shallowWater],
        startPoint: .bottom,
        endPoint: .top
    )

    /// Sunset gradient (warm colors)
    static let sunset = LinearGradient(
        colors: [.sunsetOrange, .sunsetCoral, .goldenPeach],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Wave flow gradient (blue to green)
    static let waveFlow = LinearGradient(
        colors: [.deepOcean, .coastalWater, .seaGrass],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Current flow gradient (for trajectories)
    static let currentFlow = LinearGradient(
        colors: [
            .deepOcean,
            .coastalWater,
            .seaGrass,
            .sunsetCoral,
            .sunsetOrange,
            .pinkThistle
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Tidal gradient (for backgrounds)
    static let tidal = LinearGradient(
        colors: [.oysterPearl, .shallowWater.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Storm to calm gradient
    static let stormToCalmSky = LinearGradient(
        colors: [.stormCloud, .weatheredRock, .oysterPearl],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Radial Gradients for Point Visualization

struct CoastalRadialGradients {
    /// Sea foam bubble
    static func seaFoamBubble(center: UnitPoint = .center) -> RadialGradient {
        RadialGradient(
            colors: [
                .white,
                .shallowWater,
                .coastalWater
            ],
            center: center,
            startRadius: 0,
            endRadius: 50
        )
    }

    /// Tide pool reflection
    static func tidePool(center: UnitPoint = .center) -> RadialGradient {
        RadialGradient(
            colors: [
                .coastalWater.opacity(0.8),
                .deepOcean
            ],
            center: center,
            startRadius: 0,
            endRadius: 80
        )
    }
}

// MARK: - Typography

struct CoastalTypography {
    /// Large title for main sections
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

    /// Section headers
    static let title = Font.system(size: 28, weight: .semibold, design: .default)

    /// Subsection headers
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)

    /// Body text
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Secondary text
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Emphasis text
    static let callout = Font.system(size: 16, weight: .medium, design: .default)
}

// MARK: - Spacing System (8pt grid)

struct CoastalSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct CoastalCorners {
    /// Tight radius for small elements
    static let tight: CGFloat = 6

    /// Standard radius for cards
    static let standard: CGFloat = 12

    /// Loose radius for large panels
    static let loose: CGFloat = 20

    /// Organic radius (following shell curves)
    static let organic: CGFloat = 16
}

// MARK: - Shadow System

struct CoastalShadows {
    /// Subtle shadow for slight elevation
    static let subtle = Color.black.opacity(0.05)

    /// Medium shadow for cards
    static let medium = Color.black.opacity(0.1)

    /// Strong shadow for emphasis
    static let strong = Color.black.opacity(0.2)

    /// Glow effect (for highlights)
    static func glow(_ color: Color) -> Color {
        color.opacity(0.5)
    }
}

// MARK: - Animation Curves

struct CoastalAnimations {
    /// Wave-like easing (smooth in-out)
    static let wave = Animation.easeInOut(duration: 0.8)

    /// Quick ripple effect
    static let ripple = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Gentle tide (slow, continuous)
    static let tide = Animation.easeInOut(duration: 2.0)

    /// Current flow (linear, steady)
    static let currentFlow = Animation.linear(duration: 1.5)
}

// MARK: - Helper View Modifiers

extension View {
    /// Apply coastal card style
    func coastalCard() -> some View {
        self
            .background(Color.coastalSurface)
            .cornerRadius(CoastalCorners.standard)
            .shadow(color: CoastalShadows.medium, radius: 4, x: 0, y: 2)
    }

    /// Apply coastal panel style (larger surface)
    func coastalPanel() -> some View {
        self
            .background(Color.coastalBackground)
            .cornerRadius(CoastalCorners.loose)
            .shadow(color: CoastalShadows.subtle, radius: 2, x: 0, y: 1)
    }

    /// Apply glass water effect
    func glassWaterEffect() -> some View {
        self
            .background(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.shallowWater.opacity(0.1),
                        Color.coastalWater.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CoastalCorners.organic)
    }

    /// Apply wave shimmer loading effect
    func waveShimmer() -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .shallowWater.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: -geometry.size.width)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: true
                    )
                }
            )
    }
}

// MARK: - Color Mapping Utilities

struct CoastalColorMapping {
    /// Map a normalized value (0-1) to coastal gradient
    static func coastalValue(for normalized: Double) -> Color {
        if normalized < 0.25 {
            return .deepOcean
        } else if normalized < 0.5 {
            return .coastalWater
        } else if normalized < 0.75 {
            return .seaGrass
        } else {
            return .sunsetOrange
        }
    }

    /// Map complexity score to coastal color
    static func complexityColor(for score: Int) -> Color {
        if score < 10 {
            return .deepOcean
        } else if score < 30 {
            return .coastalWater
        } else if score < 60 {
            return .seaGrass
        } else {
            return .sunsetOrange
        }
    }

    /// Map count to intensity (darker = more)
    static func countColor(for count: Int, maxCount: Int = 50) -> Color {
        let normalized = Double(count) / Double(maxCount)
        if count == 0 {
            return .beachStone
        } else if normalized < 0.2 {
            return .coastalWater
        } else if normalized < 0.5 {
            return .seaGrass
        } else if normalized < 0.8 {
            return .sunsetCoral
        } else {
            return .pinkThistle
        }
    }
}

// MARK: - Label Colors (for Manifold Configurations)

extension Color {
    /// Get distinct coastal color for configuration label
    static func coastalLabel(_ index: Int) -> Color {
        let colors: [Color] = [
            .deepOcean,
            .seaGrass,
            .sunsetOrange,
            .pinkThistle,
            .coastalWater,
            .sageGreen,
            .sunsetCoral,
            .midOcean
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Preview Helpers

#Preview("Coastal Colors") {
    ScrollView {
        VStack(spacing: CoastalSpacing.lg) {
            // Primary blues
            VStack(alignment: .leading, spacing: CoastalSpacing.xs) {
                Text("Ocean Blues")
                    .font(CoastalTypography.headline)

                HStack(spacing: CoastalSpacing.xs) {
                    ColorSwatch(color: .deepOcean, name: "Deep")
                    ColorSwatch(color: .midOcean, name: "Mid")
                    ColorSwatch(color: .coastalWater, name: "Coastal")
                    ColorSwatch(color: .shallowWater, name: "Shallow")
                }
            }

            // Greens
            VStack(alignment: .leading, spacing: CoastalSpacing.xs) {
                Text("Coastal Greens")
                    .font(CoastalTypography.headline)

                HStack(spacing: CoastalSpacing.xs) {
                    ColorSwatch(color: .seaGrass, name: "Sea Grass")
                    ColorSwatch(color: .sageGreen, name: "Sage")
                    ColorSwatch(color: .coastalVegetation, name: "Vegetation")
                }
            }

            // Warm accents
            VStack(alignment: .leading, spacing: CoastalSpacing.xs) {
                Text("Warm Accents")
                    .font(CoastalTypography.headline)

                HStack(spacing: CoastalSpacing.xs) {
                    ColorSwatch(color: .pinkThistle, name: "Thistle")
                    ColorSwatch(color: .sunsetCoral, name: "Coral")
                    ColorSwatch(color: .goldenPeach, name: "Peach")
                    ColorSwatch(color: .sunsetOrange, name: "Orange")
                }
            }

            // Gradients
            VStack(alignment: .leading, spacing: CoastalSpacing.xs) {
                Text("Gradients")
                    .font(CoastalTypography.headline)

                VStack(spacing: CoastalSpacing.xs) {
                    RoundedRectangle(cornerRadius: CoastalCorners.tight)
                        .fill(CoastalGradients.oceanDepth)
                        .frame(height: 60)
                        .overlay(Text("Ocean Depth").foregroundStyle(.white))

                    RoundedRectangle(cornerRadius: CoastalCorners.tight)
                        .fill(CoastalGradients.currentFlow)
                        .frame(height: 60)
                        .overlay(Text("Current Flow").foregroundStyle(.white))

                    RoundedRectangle(cornerRadius: CoastalCorners.tight)
                        .fill(CoastalGradients.sunset)
                        .frame(height: 60)
                        .overlay(Text("Sunset").foregroundStyle(.white))
                }
            }
        }
        .padding(CoastalSpacing.lg)
    }
    .background(Color.coastalBackground)
}

struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: CoastalCorners.tight)
                .fill(color)
                .frame(width: 60, height: 60)
                .shadow(color: CoastalShadows.medium, radius: 2)

            Text(name)
                .font(CoastalTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
