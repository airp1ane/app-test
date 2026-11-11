import Foundation

/// The list's groups, in display order.
enum DueBucket: Int, CaseIterable, Identifiable {
    case overdue, today, thisWeek, later, earlier

    var id: Self { self }

    var title: String {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .thisWeek: "This week"
        case .later: "Later"
        case .earlier: "Earlier"
        }
    }

    /// Bucketing against a window built once, for grouping a whole list.
    nonisolated static func of(dueDate due: Date, isCompleted: Bool, in window: WeekWindow) -> DueBucket {
        if due < window.startOfToday { return isCompleted ? .earlier : .overdue }
        if due < window.startOfTomorrow { return .today }
        if due < window.end { return .thisWeek }
        return .later
    }
}

/// Today plus the next six days: the span covered by the Today and This week groups
/// and by the weekly progress card.
nonisolated struct WeekWindow {
    let startOfToday: Date
    let startOfTomorrow: Date
    let end: Date

    init(now: Date = .now, calendar: Calendar = .current) {
        startOfToday = calendar.startOfDay(for: now)
        startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        end = calendar.date(byAdding: .day, value: 7, to: startOfToday)!
    }

    func contains(_ date: Date) -> Bool {
        date >= startOfToday && date < end
    }
}

nonisolated extension Calendar {
    /// Start of the Monday-to-Sunday week containing `date`, whatever this calendar's
    /// `firstWeekday` is. Other settings (time zone, `minimumDaysInFirstWeek`) are kept.
    func mondayWeekStart(for date: Date) -> Date? {
        var mondayCalendar = self
        mondayCalendar.firstWeekday = 2
        return mondayCalendar.dateInterval(of: .weekOfYear, for: date)?.start
    }

    /// `date` moved by `value` units. Adding days, weeks or months to a real date doesn't fail in
    /// practice, so returning `date` unchanged is only a defensive fallback.
    func adding(_ component: Component, _ value: Int, to date: Date) -> Date {
        self.date(byAdding: component, value: value, to: date) ?? date
    }

    /// Start of the day, week or month containing `date` (falling back to the start of its day).
    func start(of component: Component, for date: Date) -> Date {
        dateInterval(of: component, for: date)?.start ?? startOfDay(for: date)
    }

    /// Whether `date` falls on the calendar day before `reference`'s day.
    func isDayBefore(_ date: Date, relativeTo reference: Date) -> Bool {
        guard let day = self.date(byAdding: .day, value: -1, to: reference) else { return false }
        return isDate(date, inSameDayAs: day)
    }

    /// Whether `date` falls on the calendar day after `reference`'s day.
    func isDayAfter(_ date: Date, relativeTo reference: Date) -> Bool {
        guard let day = self.date(byAdding: .day, value: 1, to: reference) else { return false }
        return isDate(date, inSameDayAs: day)
    }

    /// How many days the month containing `date` has.
    func daysInMonth(of date: Date) -> Int {
        range(of: .day, in: .month, for: date)?.count ?? 30
    }
}

nonisolated extension Date {
    /// Short due label for list rows: "11:59 PM", "Thu, 9:00 AM", "Oct 12, 9:00 AM".
    func dueRowLabel(now: Date = .now, calendar: Calendar = .current) -> String {
        let time = formatted(date: .omitted, time: .shortened)
        if calendar.isDate(self, inSameDayAs: now) { return time }
        if calendar.isDayBefore(self, relativeTo: now) { return "Yesterday, \(time)" }
        if WeekWindow(now: now, calendar: calendar).contains(self) {
            return "\(formatted(.dateTime.weekday(.abbreviated))), \(time)"
        }
        let sameYear = calendar.isDate(self, equalTo: now, toGranularity: .year)
        let day = sameYear
            ? formatted(.dateTime.month(.abbreviated).day())
            : formatted(.dateTime.month(.abbreviated).day().year())
        return "\(day), \(time)"
    }

    /// Day label for the detail screen: "Today", "Tomorrow", "Thu, Oct 1".
    func dueDayLabel(now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(self, inSameDayAs: now) { return "Today" }
        if calendar.isDayAfter(self, relativeTo: now) { return "Tomorrow" }
        if calendar.isDayBefore(self, relativeTo: now) { return "Yesterday" }
        return formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

nonisolated extension Date {
    /// "Today", "Tomorrow", "Thu", or "Oct 12" for a planned work day.
    func plannedLabel(now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(self, inSameDayAs: now) { return "Today" }
        if calendar.isDayAfter(self, relativeTo: now) { return "Tomorrow" }
        if WeekWindow(now: now, calendar: calendar).contains(self) {
            return formatted(.dateTime.weekday(.abbreviated))
        }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}
