import SwiftUI

struct StreakCard: View {
    let stats: HabitStats

    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 44
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var message: String {
        if stats.allDoneToday { return "Everything due today is done." }
        if stats.openToday > 0 { return "\(stats.openToday) due today. Keep it going." }
        if stats.currentStreak == 0 { return "Finish your next assignment on time to start one." }
        return "Keep finishing before the deadline."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                TintTile(content: .icon(.streaks), color: Palette.streakOrange, size: 60, cornerRadius: 20)
                    // A quick hop when the streak changes (symbolEffect only animates SF Symbols); none with Reduce Motion.
                    .keyframeAnimator(initialValue: 1.0, trigger: reduceMotion ? 0 : stats.currentStreak) { tile, scale in
                        tile.scaleEffect(scale)
                    } keyframes: { _ in
                        SpringKeyframe(1.18, duration: 0.15)
                        SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(stats.currentStreak)")
                            .font(.system(size: numberSize, weight: .bold))
                            .tracking(-1.5)
                            .contentTransition(.numericText())
                        Text("on time in a row")
                            .font(.body.weight(.semibold))
                    }
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)

            Rectangle().fill(Palette.hairline).frame(height: 1)

            HStack(alignment: .top, spacing: 12) {
                StreakStat(
                    value: stats.onTimeRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "–",
                    label: "On time (30d)"
                )
                StreakStat(value: "\(stats.perfectWeeks)", label: "Perfect weeks")
                StreakStat(value: "\(stats.earlyFinishes)", label: "Done early")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 28)
        .animation(.snappy, value: stats.currentStreak)
    }
}
