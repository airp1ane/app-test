import SwiftUI

/// The Dusk theme as semantic tokens. Each is a color set in Assets.xcassets/Dusk with a light and
/// a dark value, so the whole app follows the system appearance. Views use these names, never raw
/// colors.
enum Palette {
    // MARK: Surfaces and text
    static let background = Color(.duskBackground)
    static let text = Color(.duskText)
    static let secondaryText = Color(.duskSecondaryText)
    static let tertiaryText = Color(.duskTertiaryText)
    static let completedText = Color(.duskCompletedText)
    /// Past day numbers, chevrons and open step rings.
    static let mutedNumber = Color(.duskMutedNumber)
    static let hairline = Color(.duskHairline)
    static let track = Color(.duskTrack)
    /// Faint fill for empty day circles and neutral chips.
    static let faintFill = Color(.duskFaintFill)
    static let dashedOutline = Color(.duskDashedOutline)

    // MARK: Accent
    static let accent = Color(.duskAccent)
    static let accentText = Color(.duskAccentText)
    /// End of the progress ring gradient.
    static let ringEnd = Color(.duskRingEnd)
    /// Solid accent buttons (+, Mark as complete). A touch deeper than the accent in dark mode,
    /// as in the dark mockup, so white text and icons on it keep their contrast.
    static let accentFill = Color(.duskAccentFill)
    /// Marks drawn on top of an accent or course-colored fill.
    static let onAccent = Color(.duskOnAccent)
    /// White in both appearances: content on solid accent fills, and glass highlight strokes.
    static let onAccentFill = Color.white

    // MARK: Status (unchanged from earlier themes)
    static let streakOrange = Color(.duskStreakOrange)
    static let onTimeGreen = Color(.duskOnTimeGreen)
    static let danger = Color(.duskDanger)
    /// Medium priority and soft warnings.
    static let warning = Color(.duskWarning)

    // MARK: Backdrop glows
    static let glowTopLeft = Color(.duskGlowTopLeft)
    static let glowRight = Color(.duskGlowRight)
    static let glowBottomLeft = Color(.duskGlowBottomLeft)
}
