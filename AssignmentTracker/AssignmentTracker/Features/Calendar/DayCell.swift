import SwiftUI

struct DayCell: View {
    let day: Date
    let isInMonth: Bool
    let isSelected: Bool
    let due: [Assignment]
    let hasPlanned: Bool
    @Environment(\.currentTime) private var now
    @Environment(\.calendar) private var calendar

    private var isToday: Bool { calendar.isDate(day, inSameDayAs: now) }
    private var isPast: Bool { day < calendar.startOfDay(for: now) }

    var body: some View {
        VStack(spacing: 3) {
            Text(day.formatted(.dateTime.day()))
                .font(.subheadline.weight(isToday || isSelected ? .bold : .medium))
                .foregroundStyle(isToday ? Palette.onAccent : (isPast ? Palette.mutedNumber : Palette.text))
                .frame(width: 34, height: 34)
                .background {
                    if isToday { Circle().fill(Palette.accent) }
                }
                .overlay {
                    // The selected day (when it isn't today) gets an accent ring.
                    if isSelected, !isToday {
                        Circle().strokeBorder(Palette.accent, lineWidth: 2)
                    }
                }

            HStack(spacing: 3) {
                ForEach(due.prefix(3)) { assignment in
                    Circle()
                        .fill(assignment.tint.opacity(assignment.isCompleted ? 0.4 : 1))
                        .frame(width: 5, height: 5)
                }
                if hasPlanned {
                    Circle()
                        .strokeBorder(Palette.accent, lineWidth: 1.2)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .opacity(isInMonth ? 1 : 0.35)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        let open = due.count { !$0.isCompleted }
        if open > 0 { parts.append("\(open) due") }
        if hasPlanned { parts.append("work planned") }
        return parts.joined(separator: ", ")
    }
}
