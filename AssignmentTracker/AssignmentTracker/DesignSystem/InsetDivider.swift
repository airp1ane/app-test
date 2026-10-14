import SwiftUI

/// A thin divider that starts after a leading tile, as in the grouped panels.
struct InsetDivider: View {
    var leading: CGFloat = 70

    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
            .padding(.leading, leading)
            .padding(.trailing, 12)
            .accessibilityHidden(true)
    }
}
