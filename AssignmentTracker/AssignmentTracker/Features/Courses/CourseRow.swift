import SwiftUI

struct CourseRow: View {
    let course: Course
    let summary: CourseSummary
    @Environment(\.currentTime) private var now
    @Environment(\.calendar) private var calendar

    var body: some View {
        HStack(spacing: 14) {
            TintTile(content: .text(summary.initials), color: course.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(course.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                Text(summary.detail(now: now, calendar: calendar))
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit course")
    }

    @ViewBuilder
    private var trailing: some View {
        switch summary.state {
        case .open(let count):
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, 9)
                .frame(minWidth: 28, minHeight: 28)
                .background(course.color, in: .capsule)
                .accessibilityLabel("\(count) to do")
        case .caughtUp:
            AppIcon(.check, size: 14, weight: 3)
                .foregroundStyle(Palette.secondaryText)
                .frame(width: 28, height: 28)
                .background(Palette.faintFill, in: .circle)
                .accessibilityLabel("All done")
        case .noAssignments:
            Color.clear.frame(width: 28, height: 28)
        }
    }
}
