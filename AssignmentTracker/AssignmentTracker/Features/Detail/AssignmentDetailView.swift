import SwiftData
import SwiftUI

struct AssignmentDetailView: View {
    @Bindable var assignment: Assignment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @FocusState private var isAddingStep: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AssignmentDetailHeader(assignment: assignment)

                StepsCard(assignment: assignment, isAddFieldFocused: $isAddingStep)

                if !assignment.isCompleted {
                    PlanCard(assignment: assignment)
                }

                if !assignment.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(0.6)
                            .foregroundStyle(Palette.secondaryText)
                            .accessibilityAddTraits(.isHeader)
                        Text(assignment.notes)
                            .font(.subheadline)
                            .lineSpacing(3)
                            .foregroundStyle(Palette.tertiaryText)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .glassCard(cornerRadius: 22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        // Room for the pinned button (58pt + its padding), so nothing can rest behind it.
        .contentMargins(.bottom, isAddingStep ? 0 : Self.buttonArea, for: .scrollContent)
        .scrollEdgeEffectStyle(.hard, for: .top)
        .scrollDismissesKeyboard(.interactively)
        .background { DuskBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Edit and delete have no glyph in the app's icon set; SF Symbol fallbacks.
                    Button("Edit", systemImage: "pencil") { isEditing = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        isConfirmingDelete = true
                    }
                } label: {
                    Label("More options", appIcon: .more)
                }
            }
        }
        .overlay(alignment: .bottom) {
            // Hidden while typing a step so it doesn't ride up over the card on the keyboard.
            if !isAddingStep {
                CompleteButton(assignment: assignment)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                    .sensoryFeedback(trigger: assignment.isCompleted) { _, isDone in isDone ? .impact(weight: .light) : nil }
            }
        }
        .sheet(isPresented: $isEditing) {
            AssignmentEditorSheet(assignment: assignment)
        }
        .confirmationDialog(
            "Delete “\(assignment.title)”?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Assignment", role: .destructive) {
                dismiss()
                assignment.delete(from: modelContext)
            }
        } message: {
            Text("This can’t be undone.")
        }
    }

    private static let buttonArea: CGFloat = 58 + 4 + 16
}

#Preview {
    let container = ModelContainer.preview
    let assignment = try! container.mainContext
        .fetch(FetchDescriptor<Assignment>(sortBy: [SortDescriptor(\.dueDate, order: .reverse)]))
        .first { !$0.steps.isEmpty }!
    return NavigationStack {
        AssignmentDetailView(assignment: assignment)
    }
    .modelContainer(container)
}
