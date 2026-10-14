import SwiftUI

/// The review screen's pinned "Add N Assignments to Class" button, with a note when past items
/// will be added as done.
struct ImportSaveBar: View {
    let model: SyllabusImportModel
    let onSave: () -> Void

    private var title: String {
        let count = model.includedCount
        let noun = count == 1 ? "Assignment" : "Assignments"
        return "Add \(count) \(noun) to \(model.course?.name ?? "Class")"
    }

    private var footnote: String? {
        let past = model.pastIncludedCount
        guard past > 0 else { return nil }
        return past == 1 ? "1 past item will be marked done" : "\(past) past items will be marked done"
    }

    var body: some View {
        VStack(spacing: 6) {
            Button(action: onSave) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Palette.onAccentFill)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .accentFill(in: Capsule())
                    .contentShape(.capsule)
            }
            .buttonStyle(.pressable(scale: 0.98))
            .disabled(model.includedCount == 0)
            .opacity(model.includedCount == 0 ? 0.5 : 1)
            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
