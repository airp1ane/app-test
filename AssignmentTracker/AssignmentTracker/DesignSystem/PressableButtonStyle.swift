import SwiftUI

/// Feedback on touch-down for buttons that aren't glass (glass buttons already react through
/// `.interactive()`). The label shrinks slightly and dims the moment a finger lands, and comes
/// back with a critically damped spring. Both run as springs, so a quick tap that lifts mid-press
/// reverses smoothly from wherever the press got to.
struct PressableButtonStyle: ButtonStyle {
    /// How far the label shrinks. Big surfaces (the full-width complete button) move less.
    var scale: CGFloat = 0.96

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Reduce Motion: no change in size, just the dim.
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            // Faster in than out: the press has to feel instant, the release can settle.
            .animation(
                configuration.isPressed ? .spring(response: 0.15, dampingFraction: 1) : .spring(response: 0.35, dampingFraction: 1),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }

    static func pressable(scale: CGFloat) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale)
    }
}
