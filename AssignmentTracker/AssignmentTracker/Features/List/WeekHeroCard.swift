import SwiftUI

/// The hero card: a progress ring for the week, the count still to go, and a Monday–Sunday strip
/// with a dot per assignment due each day.
struct WeekHeroCard: View {
    let summary: WeekHeroSummary
    let onShowDay: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ProgressRing(fraction: summary.fraction) {
                    Text("\(summary.done)/\(summary.total)")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(-0.3)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("This week")
                .accessibilityValue("\(summary.done) of \(summary.total) done")

                VStack(alignment: .leading, spacing: 2) {
                    Text("This week")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Palette.secondaryText)
                    Text("\(summary.remaining) to go")
                        .font(.title.bold())
                        .tracking(-0.5)
                        .contentTransition(.numericText())
                    Text(summary.dueTodayText)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .accessibilityHidden(true)

            HStack(spacing: 0) {
                ForEach(summary.days, id: \.date) { day in
                    Button { onShowDay(day.date) } label: {
                        StripDay(day: day)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(WeekHeroSummary.accessibilityLabel(for: day))
                    .accessibilityHint("Opens this day in Calendar")
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
        // No implicit animation here: changes arrive inside the toggle's withAnimation, and a
        // second transaction on the same glass logs "glassEffect() tried to update multiple times".
        .glassCard(cornerRadius: 28)
    }
}
