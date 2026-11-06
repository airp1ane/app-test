import SwiftUI

enum AppTab: Hashable {
    case assignments, calendar, courses, streaks
}

extension AppTab {
    var title: String {
        switch self {
        case .assignments: "Assignments"
        case .calendar: "Calendar"
        case .courses: "Courses"
        case .streaks: "Streaks"
        }
    }

    var icon: AppIcon.Name {
        switch self {
        case .assignments: .assignments
        case .calendar: .calendar
        case .courses: .courses
        case .streaks: .streaks
        }
    }

    /// The tab bar item: the outline icon as a template image, tinted by the system bar.
    var label: Label<Text, Image> {
        Label(title, appIcon: icon)
    }
}
