import SwiftUI

struct DayColumn: View {
    let day: WeekDayStatus

    var body: some View {
        VStack(spacing: 6) {
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.caption.weight(day.isToday ? .bold : .medium))
                .foregroundStyle(day.isToday ? Palette.accentText : Palette.secondaryText)
            circle
                .frame(width: 34, height: 34)
                .overlay {
                    // A ring 2pt outside the circle, drawn without changing the layout.
                    if day.isToday {
                        Circle().strokeBorder(Palette.accentText, lineWidth: 2).padding(-4)
                    }
                }
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.date.formatted(.dateTime.weekday(.wide)) + (day.isToday ? ", today" : ""))
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var circle: some View {
        switch day.kind {
        case .onTime:
            Circle()
                .fill(Palette.onTimeGreen)
                .overlay {
                    AppIcon(.check, size: 14, weight: 3)
                        .foregroundStyle(Palette.onAccent)
                }
        case .empty:
            Circle().fill(Palette.faintFill)
        case .future:
            Circle()
                .strokeBorder(Palette.dashedOutline, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                .padding(2)
        }
    }

    private var accessibilityValue: String {
        switch day.kind {
        case .onTime: "Finished on time"
        case .empty: "Nothing finished"
        case .future: "Upcoming"
        }
    }
}
