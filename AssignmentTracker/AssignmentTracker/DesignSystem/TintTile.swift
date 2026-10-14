import SwiftUI

/// A rounded-square tile showing text or a symbol in a color on a ~14% tint of that color.
struct TintTile: View {
    enum Content {
        case text(String)
        case icon(AppIcon.Name)
    }

    let content: Content
    let color: Color
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(color.opacity(0.14))
            .frame(width: size, height: size)
            .overlay {
                switch content {
                case .text(let text):
                    Text(text)
                        .font(.subheadline.bold())
                        .foregroundStyle(color)
                case .icon(let name):
                    AppIcon(name, size: size * 0.5)
                        .foregroundStyle(color)
                }
            }
            .accessibilityHidden(true)
    }
}
