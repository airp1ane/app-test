import SwiftUI

/// What the syllabus actually said about an item's date, and why it needs checking.
struct SyllabusQuoteCard: View {
    let candidate: ImportCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("In the syllabus")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Palette.secondaryText)
            if let text = candidate.dateText {
                Text("“\(text)”")
                    .font(.subheadline)
            }
            if let reason = candidate.reviewReason {
                Label { Text(reason) } icon: { AppIcon(.info, size: 16) }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Palette.warning)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
