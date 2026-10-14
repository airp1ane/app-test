import SwiftUI

/// Seven small bars, one per day, sized by how much is due that day.
struct DayLoadStrip: View {
    let start: Date
    let items: [Assignment]
    @Environment(\.currentTime) private var now

    @Environment(\.calendar) private var calendar

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.adding(.day, offset, to: start)
                let dueThatDay = items.filter { calendar.isDate($0.dueDate, inSameDayAs: day) }
                VStack(spacing: 4) {
                    // A narrow bar, so a busy day reads as taller rather than as a wide blob.
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(dueThatDay.isEmpty ? AnyShapeStyle(Palette.track) : AnyShapeStyle(barColor(for: dueThatDay)))
                        .frame(maxWidth: 18)
                        .frame(height: CGFloat(4 + min(dueThatDay.count, 4) * 7))
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption.weight(calendar.isDate(day, inSameDayAs: now) ? .bold : .regular))
                        .foregroundStyle(calendar.isDate(day, inSameDayAs: now) ? Palette.accent : Palette.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.formatted(.dateTime.weekday(.wide)))
                .accessibilityValue(dueThatDay.isEmpty ? "Nothing due" : "\(dueThatDay.count) due")
            }
        }
        .frame(height: 50, alignment: .bottom)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCard()
    }

    private func barColor(for items: [Assignment]) -> Color {
        if items.contains(where: { $0.kind == .exam }) { return Palette.danger }
        return items.count >= 3 ? Palette.warning : Palette.accent
    }
}
