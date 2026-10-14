import SwiftUI

/// One month's day cells as whole weeks, starting on the locale's first weekday.
struct MonthDays: View {
    let month: Date
    let selected: Date
    let dueByDay: [Date: [Assignment]]
    let plannedDays: Set<Date>
    let onSelect: (Date) -> Void

    @Environment(\.calendar) private var calendar

    private var days: [Date] {
        let leading = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let count = calendar.daysInMonth(of: month)
        let cells = Int(ceil(Double(leading + count) / 7)) * 7
        let start = calendar.adding(.day, -leading, to: month)
        return (0..<cells).map { calendar.adding(.day, $0, to: start) }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(days, id: \.self) { day in
                Button { onSelect(day) } label: {
                    DayCell(
                        day: day,
                        isInMonth: calendar.isDate(day, equalTo: month, toGranularity: .month),
                        isSelected: day == selected,
                        due: dueByDay[day] ?? [],
                        hasPlanned: plannedDays.contains(day)
                    )
                }
                .buttonStyle(.pressable(scale: 0.9))
            }
        }
    }
}
