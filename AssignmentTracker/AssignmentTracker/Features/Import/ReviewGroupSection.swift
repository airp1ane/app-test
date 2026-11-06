import SwiftUI

/// One group on the review screen ("Ready to add", "Needs a date"…): a header, then its rows.
struct ReviewGroupSection: View {
    let title: String
    let items: [ImportCandidate]
    let model: SyllabusImportModel
    /// The past-items group can add or skip all of its items at once.
    let showsBulkToggle: Bool
    @Binding var editing: ImportCandidate.ID?

    private var allIncluded: Bool { items.allSatisfy(\.isIncluded) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title)
                Spacer()
                if showsBulkToggle {
                    Button(allIncluded ? "Skip All" : "Add All", action: toggleAll)
                        .font(.footnote.weight(.semibold))
                        .padding(.trailing, 4)
                }
            }
            ForEach(items) { candidate in
                CandidateRow(
                    candidate: candidate,
                    courseName: model.course?.name,
                    tint: model.course?.color ?? Palette.accent,
                    onToggle: { model.toggleIncluded(candidate.id) },
                    onOpen: { editing = candidate.id }
                )
                .contextMenu {
                    Button("Edit", systemImage: "pencil") { editing = candidate.id }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        withAnimation(.snappy) { model.delete(candidate.id) }
                    }
                }
            }
        }
    }

    private func toggleAll() {
        let include = !allIncluded
        withAnimation(.snappy) { model.setPastIncluded(include) }
    }
}
