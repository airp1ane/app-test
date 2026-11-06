import SwiftUI

struct ThisWeekCard: View {
    let stats: HabitStats
    @Environment(\.currentTime) private var now

    var body: some View {
        let days = stats.weekDays(now: now)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week")
                    .font(.body.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(stats.onTimeThisWeek(now: now)) on time")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
            HStack(spacing: 6) {
                ForEach(days, id: \.date) { DayColumn(day: $0) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 18)
        .glassCard(cornerRadius: 26)
    }
}
