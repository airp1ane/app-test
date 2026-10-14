import SwiftUI

struct StripDay: View {
    let day: WeekHeroSummary.Day

    var body: some View {
        VStack(spacing: 4) {
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            Text(day.date.formatted(.dateTime.day()))
                .font(.subheadline.weight(day.isToday ? .bold : .medium))
                .foregroundStyle(day.isToday ? Palette.onAccent : (day.isPast ? Palette.mutedNumber : Palette.text))
                .frame(width: 34, height: 34)
                .background {
                    if day.isToday { Circle().fill(Palette.accent) }
                }
            HStack(spacing: 3) {
                ForEach(day.dots.prefix(4).enumerated(), id: \.offset) { _, color in
                    Circle()
                        .fill(color?.color ?? CourseColor.graphite.color)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(.rect)
    }
}
