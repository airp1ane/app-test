import CoreGraphics

/// Gesture physics shared by the swipeable views, from Apple's "Designing Fluid Interfaces".
enum Momentum {
    /// How far a flick at `velocity` (points per second) would carry if it decelerated like a
    /// scroll view (`rate` per millisecond). Add it to where the finger let go to choose a resting
    /// place from where the gesture was heading.
    nonisolated static func project(_ velocity: CGFloat, decelerationRate rate: CGFloat = 0.998) -> CGFloat {
        (velocity / 1000) * rate / (1 - rate)
    }

    /// Resistance past an edge: the further past it, the less the view follows.
    nonisolated static func rubberBand(_ overshoot: CGFloat, dimension: CGFloat, constant: CGFloat = 0.55) -> CGFloat {
        (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
    }
}
