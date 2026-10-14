import SwiftUI

struct MonthGridCard: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    let assignments: [Assignment]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Environment(\.calendar) private var calendar

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    var body: some View {
        // Built once per render, not once per day cell, and not on every frame of a swipe: the
        // drag lives in `MonthPager`, so only the pager updates while a finger moves it.
        let dueByDay = Dictionary(grouping: assignments) { calendar.startOfDay(for: $0.dueDate) }
        let plannedDays = Set(assignments.filter { !$0.isCompleted }.compactMap(\.plannedDate).map { calendar.startOfDay(for: $0) })
        VStack(spacing: 12) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                Spacer()
                Button { step(-1) } label: { AppIcon(.back, size: 20).frame(width: 44, height: 44).contentShape(.rect) }
                    .accessibilityLabel("Previous month")
                Button { step(1) } label: { AppIcon(.forward, size: 20).frame(width: 44, height: 44).contentShape(.rect) }
                    .accessibilityLabel("Next month")
            }
            .buttonStyle(.pressable)
            .font(.body.weight(.semibold))

            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(weekdaySymbols.enumerated(), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 20)
                    }
                }
                .accessibilityHidden(true)

                MonthPager(
                    month: $month,
                    selected: calendar.startOfDay(for: selectedDay),
                    dueByDay: dueByDay,
                    plannedDays: plannedDays,
                    onSelect: select
                )
            }
        }
        .padding(16)
        // Sliding months disappear at the card's edge, not under its neighbours.
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .glassCard(cornerRadius: 26)
    }

    private var stepAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 1)
    }

    private func step(_ months: Int) {
        withAnimation(stepAnimation) {
            month = calendar.adding(.month, months, to: month)
        }
    }

    private func select(_ day: Date) {
        withAnimation(stepAnimation) {
            selectedDay = day
            if !calendar.isDate(day, equalTo: month, toGranularity: .month) {
                month = calendar.start(of: .month, for: day)
            }
        }
    }
}
