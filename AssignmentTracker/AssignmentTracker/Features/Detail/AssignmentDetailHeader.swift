import SwiftUI

/// The top of the detail screen: course, title, and tags for due date, priority, weight and type.
struct AssignmentDetailHeader: View {
    let assignment: Assignment

    @Environment(\.currentTime) private var now

    private var isOverdue: Bool {
        !assignment.isCompleted && assignment.dueDate < now
    }

    private var dueText: String {
        "\(assignment.dueDate.dueDayLabel(now: now)), \(assignment.dueDate.formatted(date: .omitted, time: .shortened))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let course = assignment.course {
                HStack(spacing: 8) {
                    Circle()
                        .fill(course.color)
                        .frame(width: 8, height: 8)
                    Text(course.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.accentText)
                }
                .accessibilityElement(children: .combine)
            }

            Text(assignment.title)
                .font(.title.bold())
                .tracking(-0.7)
                .accessibilityAddTraits(.isHeader)

            FlowLayout(spacing: 8) {
                DetailTag(text: dueText, icon: .clock, color: isOverdue ? Palette.danger : nil)
                    .accessibilityLabel("Due \(dueText)")
                DetailTag(text: "\(assignment.priority.label) priority", icon: .priority, color: assignment.priority.color)
                if let weight = assignment.weight {
                    DetailTag(text: weight.hasSuffix("%") ? "\(weight) of grade" : weight, icon: .badge, color: nil)
                }
                if assignment.kind != .assignment {
                    DetailTag(text: assignment.kind.label, icon: assignment.kind.icon, color: nil)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
    }
}
