import SwiftData
import SwiftUI

/// Step two: every detected item, grouped by how much attention it needs. Items can be
/// checked off, edited, deleted or added before anything is saved.
struct ImportReviewView: View {
    @Bindable var model: SyllabusImportModel
    let onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var editing: ImportCandidate.ID?
    /// The item "Add Item" just created, until its editor closes.
    @State private var addedItem: ImportCandidate.ID?
    @State private var notificationsBlocked = false

    private enum ReviewGroup: CaseIterable {
        case check, ready, noDate, past, duplicate

        var title: String {
            switch self {
            case .check: "Check these dates"
            case .ready: "Ready to add"
            case .noDate: "Needs a date"
            case .past: "Already passed · added as done"
            case .duplicate: "Already in this class"
            }
        }
    }

    private func group(of candidate: ImportCandidate) -> ReviewGroup {
        guard candidate.dueDate != nil else { return .noDate }
        if candidate.duplicateOf != nil { return .duplicate }
        if model.isPast(candidate) { return .past }
        return candidate.reviewReason == nil ? .ready : .check
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ImportSummaryCard(model: model, notificationsBlocked: notificationsBlocked)

                if model.candidates.isEmpty {
                    ContentUnavailableView {
                        Label("No Assignments Found", appIcon: .notes)
                    } description: {
                        Text("This syllabus didn’t list any graded work the app could recognize. You can add items yourself.")
                    }
                    .glassCard()
                }

                // Sorted and grouped in one pass, not once per group.
                let grouped = Dictionary(
                    grouping: model.candidates.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) },
                    by: group(of:)
                )
                ForEach(ReviewGroup.allCases, id: \.self) { group in
                    let items = grouped[group] ?? []
                    if !items.isEmpty {
                        ReviewGroupSection(
                            title: group.title,
                            items: items,
                            model: model,
                            showsBulkToggle: group == .past,
                            editing: $editing
                        )
                    }
                }

                Button(action: addItem) {
                    HStack(spacing: 8) {
                        AppIcon(.add, size: 20)
                        Text("Add Item")
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(Palette.accentText)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .duskGlass(in: Capsule(), interactive: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .animation(.snappy, value: model.candidates)
        }
        .background { DuskBackground() }
        .task { notificationsBlocked = await ReminderScheduler.isDenied() }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            ImportSaveBar(model: model, onSave: save)
        }
        .sheet(item: Binding(
            get: { editing.flatMap { id in model.candidates.first { $0.id == id } } },
            set: { editing = $0?.id }
        ), onDismiss: discardUntitledAddedItem) { candidate in
            CandidateEditorSheet(candidate: candidate, onSave: update) {
                model.delete(candidate.id)
            }
        }
    }

    private func addItem() {
        let id = model.addCandidate()
        addedItem = id
        editing = id
    }

    /// Swiping the editor down skips Cancel, so a new item left untitled is removed here.
    private func discardUntitledAddedItem() {
        guard let id = addedItem else { return }
        addedItem = nil
        model.discardIfUntitled(id)
    }

    private func save() {
        model.save(in: modelContext)
        onFinished()
    }

    private func update(_ candidate: ImportCandidate) {
        if let index = model.candidates.firstIndex(where: { $0.id == candidate.id }) {
            model.candidates[index] = candidate
        }
    }
}
