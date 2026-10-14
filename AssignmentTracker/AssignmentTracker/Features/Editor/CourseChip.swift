import SwiftUI

/// One class as a glass chip with its color dot; the selected one gets a tint and a ring.
struct CourseChip: View {
    let course: Course
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(course.color)
                    .frame(width: 8, height: 8)
                Text(course.name)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .medium))
            .padding(.horizontal, 16)
            .frame(height: 44)
            .overlay {
                Capsule().strokeBorder(course.color.opacity(isSelected ? 1 : 0), lineWidth: 2)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.pressable)
        .background(course.color.opacity(isSelected ? 0.14 : 0), in: .capsule)
        .duskGlass(in: Capsule(), interactive: true)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
