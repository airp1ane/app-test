import SwiftUI

/// A thin capsule progress bar.
struct ThinProgressBar: View {
    let fraction: Double
    var tint: Color = Palette.accent

    var body: some View {
        Capsule()
            .fill(Palette.track)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                }
            }
            .clipShape(.capsule)
            .accessibilityHidden(true)
    }
}
