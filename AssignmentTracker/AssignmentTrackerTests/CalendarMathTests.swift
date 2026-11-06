import Foundation
import Testing
@testable import AssignmentTracker

struct CalendarMathTests {
    let calendar = Fixtures.calendar

    @Test func addingCrossesMonthAndYearBoundaries() {
        #expect(calendar.adding(.day, 1, to: Fixtures.date(2025, 12, 31)) == Fixtures.date(2026, 1, 1))
        #expect(calendar.adding(.month, -1, to: Fixtures.date(2026, 3, 1)) == Fixtures.date(2026, 2, 1))
    }

    @Test func startOfMonthAndDaysInMonth() {
        #expect(calendar.start(of: .month, for: Fixtures.date(2028, 2, 17, 15)) == Fixtures.date(2028, 2, 1))
        #expect(calendar.daysInMonth(of: Fixtures.date(2028, 2, 10)) == 29)
        #expect(calendar.daysInMonth(of: Fixtures.date(2026, 2, 10)) == 28)
    }
}
