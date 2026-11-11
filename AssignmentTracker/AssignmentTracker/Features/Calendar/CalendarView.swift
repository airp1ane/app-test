import SwiftData
import SwiftUI

/// Look-ahead planning: a month grid with what's due each day, and a weeks-ahead list for
/// spotting busy stretches early.
struct CalendarView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case month = "Month"
        case week = "Week"
        var id: Self { self }
    }

    /// Owned by `RootView`, so the Assignments week strip can open a day here.
    @Binding var selectedDay: Date
    /// Bumped by `RootView` each time a day is opened from elsewhere, so its month comes into view
    /// even when that day was already selected (and `selectedDay` doesn't change).
    var focusRequest = 0

    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]
    @Environment(\.currentTime) private var now
    @Environment(\.calendar) private var calendar
    @State private var mode: Mode = .month
    @State private var month = Calendar.current.start(of: .month, for: .now)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(
                        subtitle: now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                        title: "Calendar"
                    ) {
                        GlassCapsuleButton(title: "Today") {
                            withAnimation(.snappy) {
                                selectedDay = calendar.startOfDay(for: now)
                                show(selectedDay)
                            }
                        }
                    }

                    GlassSegmented(title: "Calendar view", options: Mode.allCases.map { ($0, $0.rawValue) }, selection: $mode)

                    switch mode {
                    case .month:
                        MonthGridCard(month: $month, selectedDay: $selectedDay, assignments: assignments)
                        DayAgenda(day: selectedDay, assignments: assignments)
                    case .week:
                        WeeksAheadList(assignments: assignments)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background { DuskBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Assignment.self) { assignment in
                AssignmentDetailView(assignment: assignment)
            }
            .onChange(of: selectedDay, initial: true) { _, day in show(day) }
            .onChange(of: focusRequest) { show(selectedDay) }
        }
    }
}

extension CalendarView {
    /// Switches to the month view with `day`'s month on screen.
    private func show(_ day: Date) {
        if !calendar.isDate(day, equalTo: month, toGranularity: .month) {
            month = calendar.start(of: .month, for: day)
        }
        mode = .month
    }
}
