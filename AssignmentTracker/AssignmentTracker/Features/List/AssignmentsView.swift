import SwiftData
import SwiftUI

/// The main screen: this week at a glance, then assignments grouped by when they're due.
struct AssignmentsView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case toDo = "To do"
        case done = "Done"

        var id: Self { self }
    }

    private struct BucketSection: Identifiable {
        let bucket: DueBucket
        let items: [Assignment]
        /// Open items in the whole bucket, regardless of the filter.
        let left: Int
        var id: DueBucket { bucket }
    }

    /// Opens a strip day in Calendar.
    var onShowDay: (Date) -> Void = { _ in }

    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]
    @Environment(\.currentTime) private var now
    @State private var filter: Filter = .all
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isAddingAssignment = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        let sections = sections
        NavigationStack {
            ScrollView {
                // Lazy, so sections far down (Later, a semester of Earlier) build only when reached.
                LazyVStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(
                        subtitle: now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                        title: "Assignments"
                    ) {
                        GlassCircleButton(icon: .search, label: isSearching ? "Close search" : "Search") {
                            withAnimation(.snappy) { toggleSearch() }
                        }
                        GlassCircleButton(icon: .add, label: "New assignment", isProminent: true) {
                            isAddingAssignment = true
                        }
                    }

                    if isSearching {
                        AssignmentSearchField(text: $searchText, isFocused: $isSearchFocused)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    WeekHeroCard(summary: hero, onShowDay: onShowDay)

                    GlassSegmented(
                        options: Filter.allCases.map { ($0, $0.rawValue) },
                        selection: $filter
                    )

                    if sections.isEmpty {
                        Group {
                            if searchText.isEmpty {
                                ContentUnavailableView {
                                    Label(filter == .done ? "Nothing Done Yet" : "No Assignments", appIcon: .assignments)
                                } description: {
                                    Text(filter == .done ? "Finished work shows up here." : "Tap + to add one, or import a syllabus.")
                                }
                            } else {
                                // The app's own search field, not `searchable()`, so pass the text.
                                ContentUnavailableView.search(text: searchText)
                            }
                        }
                        .glassCard()
                    }

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                SectionHeader(section.bucket.title)
                                Spacer()
                                Text(section.left == 0 ? "All done" : "\(section.left) left")
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.secondaryText)
                                    .padding(.trailing, 4)
                            }
                            AssignmentGroup(assignments: section.items)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .animation(.snappy, value: filter)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .scrollDismissesKeyboard(.interactively)
            .background { DuskBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Assignment.self) { assignment in
                AssignmentDetailView(assignment: assignment)
            }
            .sheet(isPresented: $isAddingAssignment) {
                AssignmentEditorSheet()
            }
        }
    }

    private func toggleSearch() {
        isSearching.toggle()
        if isSearching {
            isSearchFocused = true
        } else {
            searchText = ""
            isSearchFocused = false
        }
    }

    // MARK: - Derived data

    private var hero: WeekHeroSummary {
        WeekHeroSummary(items: assignments.map {
            WeekHeroSummary.Item(dueDate: $0.dueDate, isCompleted: $0.isCompleted, color: $0.course?.colorToken)
        }, now: now)
    }

    private var sections: [BucketSection] {
        let window = WeekWindow(now: now)
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let byBucket = Dictionary(grouping: assignments) {
            DueBucket.of(dueDate: $0.dueDate, isCompleted: $0.isCompleted, in: window)
        }
        return DueBucket.allCases.compactMap { bucket in
            let all = byBucket[bucket] ?? []
            var items = all.filter { assignment in
                switch filter {
                case .all: true
                case .toDo: !assignment.isCompleted
                case .done: assignment.isCompleted
                }
            }
            .filter { matchesSearch($0, query: query) }
            guard !items.isEmpty else { return nil }
            // Most recent first for past work; soonest first everywhere else.
            if bucket == .earlier { items.reverse() }
            return BucketSection(bucket: bucket, items: items, left: all.count { !$0.isCompleted })
        }
    }

    private func matchesSearch(_ assignment: Assignment, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return assignment.title.localizedStandardContains(query)
            || (assignment.course?.name.localizedStandardContains(query) ?? false)
            || assignment.notes.localizedStandardContains(query)
    }
}

#Preview {
    AssignmentsView()
        .modelContainer(.preview)
}
