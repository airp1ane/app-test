import Foundation
import Testing
@testable import AssignmentTracker

struct DueBucketTests {
    let window = WeekWindow(now: Fixtures.today, calendar: Fixtures.calendar)

    private func bucket(_ due: Date, done: Bool = false) -> DueBucket {
        DueBucket.of(dueDate: due, isCompleted: done, in: window)
    }

    @Test func bucketsAroundTheWeekWindow() {
        // Today is Tue Sep 29, 2026 at 10:00.
        #expect(bucket(Fixtures.date(2026, 9, 28, 23, 59)) == .overdue)
        #expect(bucket(Fixtures.date(2026, 9, 28, 23, 59), done: true) == .earlier)
        // Earlier today but past its time still counts as Today, not Overdue.
        #expect(bucket(Fixtures.date(2026, 9, 29, 8, 0)) == .today)
        #expect(bucket(Fixtures.date(2026, 9, 29, 23, 59)) == .today)
        #expect(bucket(Fixtures.date(2026, 9, 30, 0, 0)) == .thisWeek)
        #expect(bucket(Fixtures.date(2026, 10, 5, 23, 59)) == .thisWeek)
        #expect(bucket(Fixtures.date(2026, 10, 6, 0, 0)) == .later)
    }

    @Test func relativeDayLabelsUseInjectedNow() {
        // Today is Tue Sep 29, 2026 at 10:00 (the fixture clock, not the real one).
        let now = Fixtures.today
        let cal = Fixtures.calendar
        #expect(Fixtures.date(2026, 9, 29, 23, 59).dueDayLabel(now: now, calendar: cal) == "Today")
        #expect(Fixtures.date(2026, 9, 30, 9, 0).dueDayLabel(now: now, calendar: cal) == "Tomorrow")
        #expect(Fixtures.date(2026, 9, 28, 9, 0).dueDayLabel(now: now, calendar: cal) == "Yesterday")
        #expect(Fixtures.date(2026, 9, 29, 15, 0).plannedLabel(now: now, calendar: cal) == "Today")
        #expect(Fixtures.date(2026, 9, 30, 0, 0).plannedLabel(now: now, calendar: cal) == "Tomorrow")
        #expect(Fixtures.date(2026, 9, 28, 20, 0).dueRowLabel(now: now, calendar: cal).hasPrefix("Yesterday, "))
    }
}
