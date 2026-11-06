import SwiftUI

/// A small label above a text field, on a glass card: the Title, Name and Notes fields in the
/// editor sheets.
struct LabeledFieldCard<Field: View>: View {
    let label: LocalizedStringResource
    @ContentBuilder var field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Palette.secondaryText)
            field
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
