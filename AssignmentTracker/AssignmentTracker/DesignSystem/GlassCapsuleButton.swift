import SwiftUI

/// A glass capsule button with a short text label (e.g. "Today"), at least 44pt tall.
struct GlassCapsuleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.text)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .duskGlass(in: Capsule(), interactive: true)
    }
}
