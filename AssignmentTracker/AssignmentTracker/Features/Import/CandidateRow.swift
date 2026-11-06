import SwiftUI

struct CandidateRow: View {
    let candidate: ImportCandidate
    let courseName: String?
    let tint: Color
    let onToggle: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: candidate.dueDate == nil ? onOpen : onToggle) {
                CheckCircle(isOn: candidate.isIncluded, tint: candidate.dueDate == nil ? Palette.mutedNumber : tint)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(candidate.isIncluded ? "Don’t add \(candidate.title)" : "Add \(candidate.title)")

            Button(action: onOpen) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.title.isEmpty ? "Untitled" : candidate.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(candidate.isIncluded ? Palette.text : Palette.completedText)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            AppIcon(candidate.kind.icon, size: 14)
                            Text(dateLabel)
                            if let weight = candidate.weight {
                                Text("·")
                                Text(weight)
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)

                        if let note = attentionNote {
                            // No duplicate or warning glyph in the app's icon set; SF Symbol fallbacks.
                            Label(note, systemImage: candidate.duplicateOf != nil ? "doc.on.doc" : "exclamationmark.triangle")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(candidate.duplicateOf != nil ? Palette.secondaryText : Palette.warning)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    AppIcon(.forward, size: 16)
                        .foregroundStyle(Palette.mutedNumber)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
            }
            .buttonStyle(.pressable)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 4)
        .glassCard(cornerRadius: 22)
    }

    private var dateLabel: String {
        guard let due = candidate.dueDate else { return candidate.dateText ?? "No date" }
        let day = due.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        return "\(day), \(due.formatted(date: .omitted, time: .shortened))"
    }

    private var attentionNote: String? {
        if let duplicate = candidate.duplicateOf {
            return "Already in \(courseName ?? "this class") as “\(duplicate)”"
        }
        return candidate.reviewReason
    }
}
