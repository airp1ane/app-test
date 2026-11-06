import SwiftUI

/// An assignment with no class, and a menu to give it one.
struct CoursePickerRow: View {
    let assignment: Assignment
    let courses: [Course]

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                Text(assignment.dueDate.dueRowLabel())
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Menu {
                ForEach(courses) { course in
                    Button(course.name) { assign(course) }
                }
            } label: {
                Text("Choose")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accentText)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .disabled(courses.isEmpty)
            .accessibilityLabel("Choose a course for \(assignment.title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func assign(_ course: Course) {
        withAnimation(.snappy) { assignment.course = course }
        ReminderScheduler.sync(assignment)
    }
}
