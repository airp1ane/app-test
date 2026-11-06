import SwiftData
import SwiftUI

/// The classes, as one grouped glass list. Tap one to rename, recolor or delete it.
struct CoursesView: View {
    @Query(sort: \Course.sortIndex) private var courses: [Course]
    @Query private var assignments: [Assignment]
    @State private var editing: Course?
    @State private var isAdding = false
    @State private var isImporting = false
    @State private var isAssigning = false

    private func makeSummaries() -> [(course: Course, summary: CourseSummary)] {
        courses.map { course in
            (course, CourseSummary(
                name: course.name,
                assignments: course.assignments.map { ($0.title, $0.dueDate, $0.isCompleted) }
            ))
        }
    }

    private func subtitle(for summaries: [(course: Course, summary: CourseSummary)], unassigned: [Assignment]) -> String {
        // Open work in every course, plus open work with no course yet.
        let toDo = summaries.reduce(0) { $0 + $1.summary.openCount } + unassigned.count { !$0.isCompleted }
        let courseWord = courses.count == 1 ? "course" : "courses"
        return "\(courses.count) \(courseWord) · \(toDo) to do"
    }

    var body: some View {
        // Built once per render; the header and the list both use them.
        let summaries = makeSummaries()
        let unassigned = assignments.filter { $0.course == nil }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(subtitle: subtitle(for: summaries, unassigned: unassigned), title: "Courses") {
                        GlassCircleButton(icon: .scan, label: "Import syllabus") {
                            isImporting = true
                        }
                        GlassCircleButton(icon: .add, label: "Add course", isProminent: true) {
                            isAdding = true
                        }
                    }

                    if courses.isEmpty {
                        ContentUnavailableView {
                            Label("No Courses", appIcon: .courses)
                        } description: {
                            Text("Add a course, or import a syllabus to create one with its assignments.")
                        }
                        .glassCard(cornerRadius: 26)
                    } else {
                        GlassGroup {
                            ForEach(summaries.enumerated(), id: \.element.course.id) { index, item in
                                if index > 0 { InsetDivider() }
                                Button { editing = item.course } label: {
                                    CourseRow(course: item.course, summary: item.summary)
                                }
                                .buttonStyle(.pressable)
                            }
                        }
                    }

                    if !unassigned.isEmpty {
                        UnassignedRow(count: unassigned.count) { isAssigning = true }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background { DuskBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(item: $editing) { CourseEditorSheet(course: $0) }
            .sheet(isPresented: $isAdding) { CourseEditorSheet() }
            .sheet(isPresented: $isImporting) { SyllabusImportSheet() }
            .sheet(isPresented: $isAssigning) { AssignToCourseSheet() }
        }
    }
}

#Preview {
    CoursesView()
        .modelContainer(.preview)
}
