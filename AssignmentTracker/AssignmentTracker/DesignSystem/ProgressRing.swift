import SwiftUI

/// A progress ring: a track with an accent-to-pink gradient arc and content in the middle.
struct ProgressRing<Center: View>: View {
    let fraction: Double
    var diameter: CGFloat = 76
    var lineWidth: CGFloat = 8
    @ViewBuilder var center: Center

    var body: some View {
        let clamped = min(max(fraction, 0), 1)
        ZStack {
            Group {
                Circle()
                    .stroke(Palette.track, lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(
                        AngularGradient(
                            colors: [Palette.accent, Palette.ringEnd],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(max(360 * clamped, 1))
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            // Inset by half the stroke so the ring's outer edge is exactly `diameter`.
            .padding(lineWidth / 2)
            center
        }
        .frame(width: diameter, height: diameter)
        .animation(.snappy, value: fraction)
    }
}
