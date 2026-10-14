import SwiftUI

/// A 44pt circular icon button: Dusk glass, or a solid accent fill for the primary action.
/// Icon-only, so it always needs an accessibility label.
struct GlassCircleButton: View {
    let icon: AppIcon.Name
    let label: String
    var isProminent = false
    let action: () -> Void

    var body: some View {
        if isProminent {
            // The fill is part of the label, so the whole disc presses in, not just the icon.
            Button(action: action) {
                AppIcon(icon, size: 22, weight: 2.2)
                    .foregroundStyle(Palette.onAccentFill)
                    .frame(width: 44, height: 44)
                    .accentFill(in: Circle())
                    .contentShape(.circle)
            }
            .buttonStyle(.pressable(scale: 0.92))
            .accessibilityLabel(label)
        } else {
            // Interactive glass gives its own press response.
            Button(action: action) {
                AppIcon(icon, size: 20)
                    .foregroundStyle(Palette.text)
                    .frame(width: 44, height: 44)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .duskGlass(in: Circle(), interactive: true)
            .accessibilityLabel(label)
        }
    }
}
