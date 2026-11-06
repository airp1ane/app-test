import SwiftUI

/// The glass search field that drops in below the Assignments header, with a clear button once
/// there's text.
struct AssignmentSearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            AppIcon(.search, size: 18)
                .foregroundStyle(Palette.secondaryText)
            TextField("Search assignments", text: $text)
                .focused(isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button(action: clear) {
                    AppIcon(.close, size: 16)
                        .foregroundStyle(Palette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, text.isEmpty ? 16 : 0)
        .frame(minHeight: 48)
        .glassCard(cornerRadius: 24)
    }

    private func clear() {
        text = ""
    }
}
