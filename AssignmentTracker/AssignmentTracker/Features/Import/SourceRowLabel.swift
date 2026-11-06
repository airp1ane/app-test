import SwiftUI

struct SourceRowLabel: View {
    let title: String
    var icon: AppIcon.Name?
    var fallbackSymbol: String?

    var body: some View {
        HStack {
            if let icon {
                RowLabel(title, icon: icon)
            } else {
                RowLabel.SymbolFallback(title: title, systemImage: fallbackSymbol ?? "")
            }
            Spacer()
            AppIcon(.forward, size: 16)
                .foregroundStyle(Palette.mutedNumber)
        }
        .frame(minHeight: 52)
        .contentShape(.rect)
    }
}
