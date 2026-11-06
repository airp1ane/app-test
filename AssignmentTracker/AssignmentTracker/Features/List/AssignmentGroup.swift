import SwiftUI

/// Assignments as one grouped glass panel with inset hairlines (54pt in, 12pt from the right).
struct AssignmentGroup: View {
    let assignments: [Assignment]
    /// A tag per row, keyed by assignment (e.g. "Planned").
    var tag: (Assignment) -> String? = { _ in nil }

    var body: some View {
        GlassGroup {
            ForEach(assignments.enumerated(), id: \.element.id) { index, assignment in
                if index > 0 { InsetDivider(leading: 54) }
                AssignmentRow(assignment: assignment, tag: tag(assignment))
            }
        }
    }
}
