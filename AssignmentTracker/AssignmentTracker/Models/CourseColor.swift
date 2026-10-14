import SwiftUI

/// Stored by name so each course shows its light or dark variant automatically. New cases can be
/// added freely; existing courses keep decoding by their raw value.
nonisolated enum CourseColor: String, Codable, CaseIterable {
    case blue, indigo, purple, pink, red, orange, amber, green, teal, cyan, brown, graphite

    /// Dusk hues (color sets in Assets.xcassets/Course). Blue, pink, purple and teal are the theme's
    /// course colors; the rest are tuned to sit with them and stay readable on glass in both
    /// appearances.
    @MainActor var color: Color {
        switch self {
        case .blue: Color(.courseBlue)
        case .indigo: Color(.courseIndigo)
        case .purple: Color(.coursePurple)
        case .pink: Color(.coursePink)
        case .red: Color(.courseRed)
        case .orange: Color(.courseOrange)
        case .amber: Color(.courseAmber)
        case .green: Color(.courseGreen)
        case .teal: Color(.courseTeal)
        case .cyan: Color(.courseCyan)
        case .brown: Color(.courseBrown)
        case .graphite: Color(.courseGraphite)
        }
    }

    var name: String { rawValue.capitalized }
}
