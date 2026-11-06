import SwiftUI

struct WeekSection: View {
    let title: String
    let start: Date
    let items: [Assignment]

    @Environment(\.calendar) private var calendar

    private var open: [Assignment] { items.filter { !$0.isCompleted } }
    private var examCount: Int { open.count { $0.kind == .exam } }
    private var isBusy: Bool { open.count >= 5 || examCount > 0 }

    private var summary: String {
        guard !items.isEmpty else { return "Nothing due" }
        var parts = ["\(open.count) due"]
        if examCount > 0 { parts.append(examCount == 1 ? "1 exam" : "\(examCount) exams") }
        if open.count < items.count { parts.append("\(items.count - open.count) done") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title)
                Spacer()
                if isBusy {
                    // No warning glyph in the app's icon set; outline SF Symbol fallback.
                    Label("Busy", systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.warning)
                }
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
            .padding(.trailing, 4)

            if !items.isEmpty {
                DayLoadStrip(start: start, items: open)
                AssignmentGroup(assignments: open)
            }
        }
    }
}
