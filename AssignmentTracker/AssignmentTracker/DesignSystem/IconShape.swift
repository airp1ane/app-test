import SwiftUI

/// An icon glyph scaled from the 24pt grid to any frame.
struct IconShape: Shape {
    let name: AppIcon.Name

    nonisolated func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        return name.gridPath.applying(
            CGAffineTransform(translationX: rect.midX - 12 * scale, y: rect.midY - 12 * scale).scaledBy(x: scale, y: scale)
        )
    }
}
