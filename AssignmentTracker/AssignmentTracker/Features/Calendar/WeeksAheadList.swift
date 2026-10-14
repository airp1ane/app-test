import SwiftUI

/// The next eight weeks at a glance: how much is due each week and on which days, so busy
/// stretches (several deadlines, an exam) show up early enough to plan around.
struct WeeksAheadList: View {
    let assignments: [Assignment]
    @Environment(\.currentTime) private var now

    @Environment(\.calendar) private var calendar
    private static let weekCount = 8

    private struct Week: Identifiable {
        let start: Date
        let items: [Assignment]
        var id: Date { start }
    }

    private var overdue: [Assignment] {
        let startOfToday = calendar.startOfDay(for: now)
        return assignments.filter { !$0.isCompleted && $0.dueDate < startOfToday }
    }

    private var weeks: [Week] {
        let thisWeek = calendar.start(of: .weekOfYear, for: now)
        return (0..<Self.weekCount).map { offset in
            let start = calendar.adding(.weekOfYear, offset, to: thisWeek)
            let end = calendar.adding(.weekOfYear, 1, to: start)
            return Week(start: start, items: assignments.filter { $0.dueDate >= start && $0.dueDate < end })
        }
    }

    var body: some View {
        let overdueItems = overdue
        VStack(alignment: .leading, spacing: 22) {
            if !overdueItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("Overdue")
                    AssignmentGroup(assignments: overdueItems)
                }
            }
            ForEach(weeks.enumerated(), id: \.element.id) { index, week in
                WeekSection(title: title(for: week, index: index), start: week.start, items: week.items)
            }
        }
    }

    private func title(for week: Week, index: Int) -> String {
        switch index {
        case 0: return "This week"
        case 1: return "Next week"
        default:
            let end = calendar.adding(.day, 6, to: week.start)
            return "\(week.start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
        }
    }
}
