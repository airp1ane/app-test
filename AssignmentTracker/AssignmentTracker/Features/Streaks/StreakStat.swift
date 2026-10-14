import SwiftUI

struct StreakStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .contentTransition(.numericText())
            Text(label)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
