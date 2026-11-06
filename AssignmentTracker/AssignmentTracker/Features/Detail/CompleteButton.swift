import SwiftUI

/// The detail screen's pinned button: a solid "Mark as complete", or a glass "Completed · Undo".
struct CompleteButton: View {
    let assignment: Assignment

    var body: some View {
        if assignment.isCompleted {
            Button(action: assignment.toggleCompleted) {
                HStack(spacing: 10) {
                    AppIcon(.check, size: 20, weight: 2.4)
                    Text("Completed · Undo")
                }
                .font(.headline)
                .foregroundStyle(Palette.accentText)
                .frame(maxWidth: .infinity, minHeight: 58)
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .duskGlass(in: Capsule(), interactive: true)
        } else {
            Button(action: assignment.toggleCompleted) {
                HStack(spacing: 10) {
                    AppIcon(.check, size: 20, weight: 2.4)
                    Text("Mark as complete")
                }
                .font(.headline)
                .foregroundStyle(Palette.onAccentFill)
                .frame(maxWidth: .infinity, minHeight: 58)
                .accentFill(in: Capsule())
                .contentShape(.capsule)
            }
            .buttonStyle(.pressable(scale: 0.98))
        }
    }
}
