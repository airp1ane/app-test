import SwiftData
import SwiftUI

/// Gives class-less assignments a course, one menu per assignment.
struct AssignToCourseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.sortIndex) private var courses: [Course]
    @Query(filter: #Predicate<Assignment> { $0.course == nil }, sort: \Assignment.dueDate)
    private var unassigned: [Assignment]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if unassigned.isEmpty {
                        ContentUnavailableView {
                            Label("All Assigned", appIcon: .check)
                        } description: {
                            Text("Every assignment has a course.")
                        }
                        .glassCard(cornerRadius: 26)
                    } else {
                        GlassGroup {
                            ForEach(unassigned.enumerated(), id: \.element.id) { index, assignment in
                                if index > 0 { InsetDivider(leading: 12) }
                                CoursePickerRow(assignment: assignment, courses: courses)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background { DuskBackground() }
            .navigationTitle("Assign Courses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { dismiss() } label: { Label("Done", appIcon: .check) }
                }
            }
        }
    }
}
