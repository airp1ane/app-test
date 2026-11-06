import SwiftData
import SwiftUI

/// The four tabs in the system Liquid Glass tab bar (with the app's own icons), plus app-wide
/// celebrations when a streak or day is completed.
struct RootView: View {
    @Query private var assignments: [Assignment]
    @State private var tab: AppTab = .assignments
    /// The day shown in Calendar; the Assignments week strip sets it.
    @State private var calendarDay = Calendar.current.startOfDay(for: .now)
    @State private var calendarFocus = 0
    @State private var celebration: Celebration?
    /// How far the toast is being dragged; while it's held it doesn't time out.
    @State private var toastOffset: CGFloat = 0
    @State private var isHoldingToast = false
    /// Worked out when completion history changes (or the time does), not on every render.
    @State private var stats = HabitStats()
    @State private var lastStats: HabitStats?
    @State private var lastStatsDay = Calendar.current.startOfDay(for: .now)
    /// Finished items at the last update. Celebrations need this to go up, so deleting or
    /// rescheduling an open item can't trigger "All done for today" or a streak milestone.
    @State private var lastFinishedCount = 0
    /// The time the screens compare due dates against. It moves on at each due time, at midnight
    /// and when the app comes back, so "Today", "Overdue" and the streak stay right without
    /// rebuilding the tabs (which would throw away open sheets and navigation).
    @State private var now = Date.now
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.calendar) private var calendar

    private var records: [CompletionRecord] {
        assignments.map(\.completionRecord)
    }

    /// The soonest due time still ahead for open work: when something next turns overdue.
    private var nextDueTime: Date? {
        assignments.lazy.filter { !$0.isCompleted && $0.dueDate > now }.map(\.dueDate).min()
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab(value: AppTab.assignments) {
                AssignmentsView { day in
                    calendarDay = day
                    calendarFocus += 1
                    withAnimation(.snappy) { tab = .calendar }
                }
            } label: { AppTab.assignments.label }
            Tab(value: AppTab.calendar) {
                CalendarView(selectedDay: $calendarDay, focusRequest: calendarFocus)
            } label: { AppTab.calendar.label }
            Tab(value: AppTab.courses) {
                CoursesView()
            } label: { AppTab.courses.label }
            Tab(value: AppTab.streaks) {
                StreaksView(stats: stats)
            } label: { AppTab.streaks.label }
        }
        .environment(\.currentTime, now)
        .foregroundStyle(Palette.text)
        .overlay(alignment: .top) {
            if let celebration {
                CelebrationToast(celebration: celebration)
                    .offset(y: toastOffset)
                    .padding(.top, 8)
                    // It leaves the way it came in: back up off the top.
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    // A tap gesture rather than a Button, so the swipe below can share the toast.
                    .onTapGesture { dismissToast(velocity: 0) }
                    .gesture(toastSwipe)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Dismisses")
            }
        }
        .sensoryFeedback(.success, trigger: celebration) { _, new in new != nil }
        .onChange(of: records, initial: true) { _, records in
            updateStats(from: records, celebrate: true)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshTime() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshTime()
        }
        .task(id: nextDueTime) {
            guard let nextDueTime else { return }
            try? await Task.sleep(for: .seconds(max(nextDueTime.timeIntervalSinceNow, 0) + 1))
            guard !Task.isCancelled else { return }
            refreshTime()
        }
        .task(id: ToastTimer(celebration: celebration, isHeld: isHoldingToast)) {
            guard celebration != nil, !isHoldingToast else { return }
            await clearAfterDelay(.seconds(3)) {
                withAnimation(.snappy) { celebration = nil }
            }
        }
    }
}

/// Waits for `delay`, then runs `clear`. A newer celebration (or a tap) cancels the task, and a
/// cancelled wait must not clear the toast that replaced it.
@MainActor
func clearAfterDelay(_ delay: Duration, clear: () -> Void) async {
    try? await Task.sleep(for: delay)
    guard !Task.isCancelled else { return }
    clear()
}

/// The fallback for `currentTime` outside `RootView` (previews). Fixed once, because an `@Entry`
/// default is evaluated on every read and `.now` would differ each time.
private let launchTime = Date.now

extension EnvironmentValues {
    /// The time screens compare due dates against, kept by `RootView` (see `now` there).
    @Entry var currentTime: Date = launchTime
}

extension RootView {
    /// Moves `now` on; every screen that shows "Today" or "Overdue" reads it.
    private func refreshTime() {
        // Calendar was showing today: keep it on today once the day changes.
        if calendar.isDate(calendarDay, inSameDayAs: now), !calendar.isDate(now, inSameDayAs: .now) {
            calendarDay = calendar.startOfDay(for: .now)
        }
        now = .now
        // Time passing isn't an achievement: update without celebrating.
        updateStats(from: records, celebrate: false)
    }

    private func updateStats(from records: [CompletionRecord], celebrate: Bool) {
        let new = HabitStats(records: records)
        // The first value is just the app opening, and a change of day isn't progress:
        // only changes within the same day are celebrated.
        let old = lastStats
        let statsDay = lastStatsDay
        let finished = records.count { $0.completedAt != nil }
        let finishedMore = finished > lastFinishedCount
        stats = new
        lastStats = new
        lastStatsDay = calendar.startOfDay(for: .now)
        lastFinishedCount = finished
        guard celebrate, finishedMore, calendar.isDateInToday(statsDay),
              let old, let found = new.celebration(since: old) else { return }
        toastOffset = 0
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.3)) { celebration = found }
    }

    /// The toast follows the finger. Up is the way out; down it resists more the further it's
    /// pulled, since there's nowhere for it to go.
    private var toastSwipe: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                isHoldingToast = true
                let y = value.translation.height
                toastOffset = y < 0 ? y : Momentum.rubberBand(y, dimension: 120)
            }
            .onEnded { value in
                isHoldingToast = false
                let velocity = value.velocity.height
                // Throw it by where the swipe was heading, not just where the finger let go.
                if toastOffset + Momentum.project(velocity) < -30 {
                    dismissToast(velocity: velocity)
                } else {
                    let relative = toastOffset != 0 ? velocity / -toastOffset : 0
                    withAnimation(.interpolatingSpring(Spring(response: 0.35, dampingRatio: 0.8), initialVelocity: relative)) {
                        toastOffset = 0
                    }
                }
            }
    }

    private func dismissToast(velocity: CGFloat) {
        // Faster swipes leave faster.
        let response = velocity < -600 ? 0.25 : 0.35
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: response, dampingFraction: 1)) {
            celebration = nil
        }
    }
}

#Preview {
    RootView()
        .modelContainer(.preview)
}
