//
//  SharedViewComponents.swift
//  PersistenceViewer
//
//  Shared UI components used across multiple views
//

import SwiftUI
import RealityKit

// MARK: - Dimension Toggle

struct DimensionToggle: View {
    let dimension: Int
    @Binding var isOn: Bool
    let color: Color
    let label: String

    var body: some View {
        Button(action: {
            withAnimation {
                isOn.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isOn ? color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                Text(label)
                    .font(.caption)
                    .foregroundColor(isOn ? .primary : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOn ? color.opacity(0.1) : Color.clear)
            .cornerRadius(CoastalCorners.tight)
        }
    }
}

// MARK: - Entity Extensions

extension Entity {
    func withChild(_ child: Entity) -> Entity {
        self.addChild(child)
        return self
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    static func interpolate(from startColor: UIColor, to endColor: UIColor, progress: CGFloat) -> UIColor {
        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0

        startColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

        let red = startRed + (endRed - startRed) * progress
        let green = startGreen + (endGreen - startGreen) * progress
        let blue = startBlue + (endBlue - startBlue) * progress
        let alpha = startAlpha + (endAlpha - startAlpha) * progress

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
