import SwiftUI

/// "N assignments have no course · Assign", below the course list; opens the assign sheet.
struct UnassignedRow: View {
    let count: Int
    let action: () -> Void

    private var text: String {
        count == 1 ? "1 assignment has no course" : "\(count) assignments have no course"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AppIcon(.notes, size: 22)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(width: 24)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                Spacer(minLength: 8)
                Text("Assign")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accentText)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: 22, interactive: true)
        .accessibilityLabel(text)
        .accessibilityHint("Choose a course for each")
    }
}
