import SwiftUI

/// Edits one detected item on the review screen. Changes apply on Done.
struct CandidateEditorSheet: View {
    let original: ImportCandidate
    let onSave: (ImportCandidate) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: ImportCandidate
    @State private var hasDate: Bool
    @State private var date: Date

    init(candidate: ImportCandidate, onSave: @escaping (ImportCandidate) -> Void, onDelete: @escaping () -> Void) {
        self.original = candidate
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: candidate)
        _hasDate = State(initialValue: candidate.dueDate != nil)
        _date = State(initialValue: candidate.dueDate ?? Self.tomorrowEvening())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if original.dateText != nil || original.reviewReason != nil {
                        SyllabusQuoteCard(candidate: original)
                    }

                    LabeledFieldCard(label: "Title") {
                        TextField("e.g. Problem Set 3", text: $draft.title)
                            .font(.title3.weight(.semibold))
                    }

                    CandidateDetailsCard(draft: $draft, hasDate: $hasDate, date: $date)

                    LabeledFieldCard(label: "Notes") {
                        TextField("Add details", text: $draft.notes, axis: .vertical)
                            .lineLimit(2...8)
                    }

                    Button(role: .destructive, action: remove) {
                        // No delete glyph in the app's icon set; SF Symbol fallback.
                        Label("Remove from Import", systemImage: "trash")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Palette.danger)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .duskGlass(in: Capsule(), interactive: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background { DuskBackground() }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(original.title.isEmpty ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel, action: cancel) { Label("Cancel", appIcon: .close) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save) { Label("Done", appIcon: .check) }
                        .disabled(CandidateText.isBlank(draft.title))
                }
            }
        }
    }

    private func remove() {
        onDelete()
        dismiss()
    }

    private func cancel() {
        // A brand-new, untouched item is discarded rather than left blank.
        if original.title.isEmpty, CandidateText.isBlank(draft.title) { onDelete() }
        dismiss()
    }

    private func save() {
        var updated = draft
        updated.title = updated.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if hasDate {
            if updated.dueDate != date || updated.reviewReason != nil {
                // Picking or confirming a date resolves the review flag.
                updated.dueDate = date
                updated.dateStatus = .confident
                updated.dateSetByUser = true
            }
            // A newly dated item becomes importable unless it duplicates one in the class.
            if original.dueDate == nil, updated.duplicateOf == nil { updated.isIncluded = true }
        } else {
            updated.dueDate = nil
            updated.dateStatus = .missing("No date")
            updated.dateSetByUser = true
            updated.isIncluded = false
        }
        onSave(updated)
        dismiss()
    }

    private static func tomorrowEvening() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.adding(.day, 1, to: calendar.startOfDay(for: .now))
        return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: tomorrow) ?? tomorrow
    }
}
