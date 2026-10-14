import SwiftUI

/// One glass panel holding rows that are separated by thin inset dividers.
struct GlassGroup<Content: View>: View {
    var cornerRadius: CGFloat = 26
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: cornerRadius)
    }
}
