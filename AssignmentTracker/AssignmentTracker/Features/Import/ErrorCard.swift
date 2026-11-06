import SwiftUI

struct ErrorCard: View {
    let error: SyllabusImportError

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AppIcon(.info, size: 24)
                .foregroundStyle(Palette.danger)
            VStack(alignment: .leading, spacing: 4) {
                Text(error.errorDescription ?? "Something went wrong.")
                    .font(.subheadline.weight(.semibold))
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}
