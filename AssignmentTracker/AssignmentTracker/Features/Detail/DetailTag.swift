import SwiftUI

/// A small glass capsule with an icon, for the due date, priority, weight and type.
struct DetailTag: View {
    let text: String
    let icon: AppIcon.Name
    /// Colors icon and text; nil uses the text color with a secondary icon.
    let color: Color?

    var body: some View {
        HStack(spacing: 8) {
            AppIcon(icon, size: 16)
                .foregroundStyle(color ?? Palette.secondaryText)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color ?? Palette.text)
        }
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .frame(minHeight: 36)
        .duskGlass(in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
