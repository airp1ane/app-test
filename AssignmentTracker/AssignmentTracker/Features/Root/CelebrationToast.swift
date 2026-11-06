import SwiftUI

struct CelebrationToast: View {
    let celebration: Celebration
    @State private var bounce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.calendar) private var calendar

    var body: some View {
        HStack(spacing: 12) {
            AppIcon(celebration.icon, size: 26)
                .foregroundStyle(Palette.streakOrange)
                .scaleEffect(bounce || reduceMotion ? 1 : 0.6)
                .animation(.spring(duration: 0.4, bounce: 0.5), value: bounce)
            VStack(alignment: .leading, spacing: 2) {
                Text(celebration.title)
                    .font(.subheadline.weight(.semibold))
                Text(celebration.detail)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .duskGlass(in: Capsule())
        .onAppear { bounce = true }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
