import SwiftUI

/// A badge as a list row: earned ones say so, locked ones show progress.
struct BadgeRow: View {
    let badge: Badge

    var body: some View {
        HStack(alignment: badge.isUnlocked ? .center : .top, spacing: 14) {
            TintTile(
                content: .icon(badge.isUnlocked ? badge.icon : .locked),
                color: badge.isUnlocked ? Palette.streakOrange : Palette.completedText
            )
            if badge.isUnlocked {
                VStack(alignment: .leading, spacing: 3) {
                    Text(badge.title)
                        .font(.body.weight(.semibold))
                    Text(badge.detail)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Earned")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(badge.title)
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text("\(min(badge.current, badge.goal)) / \(badge.goal)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                            .monospacedDigit()
                    }
                    ThinProgressBar(fraction: badge.fraction, tint: Palette.streakOrange)
                    Text(badge.detail)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityValue(badge.isUnlocked ? "Earned" : "\(min(badge.current, badge.goal)) of \(badge.goal)")
    }
}
