import SwiftUI

/// The classes as tappable chips, for picking one, with an optional "New Class" chip at the end.
struct CourseChips: View {
    let courses: [Course]
    @Binding var selection: Course?
    /// When set, a trailing "New Class" chip calls this.
    var onAddCourse: (() -> Void)?

    var body: some View {
        GlassEffectContainer {
            FlowLayout(spacing: 8) {
                ForEach(courses) { course in
                    CourseChip(course: course, isSelected: course == selection) {
                        withAnimation(.snappy) { selection = course }
                    }
                }
                if let onAddCourse {
                    Button(action: onAddCourse) {
                        HStack(spacing: 6) {
                            AppIcon(.add, size: 16)
                            Text("New Class")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.accentText)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .duskGlass(in: Capsule(), interactive: true)
                }
            }
        }
    }
}
