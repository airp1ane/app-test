import SwiftUI

/// The selected day's items in one glass panel: what's due, then planned work sessions.
struct DayAgenda: View {
    let day: Date
    let assignments: [Assignment]
    @Environment(\.currentTime) private var now

    @Environment(\.calendar) private var calendar

    private var range: Range<Date> {
        let start = calendar.startOfDay(for: day)
        return start..<calendar.adding(.day, 1, to: start)
    }

    private var title: String {
        calendar.isDate(day, inSameDayAs: now) ? "Today" : day.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        let range = range
        let due = assignments.filter { range.contains($0.dueDate) }
        let planned = assignments.filter {
            !$0.isCompleted && $0.plannedDate.map(range.contains) == true && !range.contains($0.dueDate)
        }
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title)
                Spacer()
                let open = due.count { !$0.isCompleted }
                if !due.isEmpty {
                    Text(open == 0 ? "All done" : "\(open) left")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.trailing, 4)
                }
            }

            if due.isEmpty && planned.isEmpty {
                Text("Nothing due or planned. A good day to get ahead.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    .glassCard(cornerRadius: 26)
            } else {
                let plannedIDs = Set(planned.map(\.id))
                AssignmentGroup(assignments: due + planned) { plannedIDs.contains($0.id) ? "Planned" : nil }
            }
        }
    }
}
