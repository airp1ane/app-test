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
    @State private var mode: Mode = .month
    @State private var month = Calendar.current.dateInterval(of: .month, for: .now)!.start

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
                                selectedDay = Calendar.current.startOfDay(for: now)
                                show(selectedDay)
                            }
                        }
                    }

                    GlassSegmented(options: Mode.allCases.map { ($0, $0.rawValue) }, selection: $mode)

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
        let calendar = Calendar.current
        if !calendar.isDate(day, equalTo: month, toGranularity: .month) {
            month = calendar.dateInterval(of: .month, for: day)!.start
        }
        mode = .month
    }
}

// MARK: - Month grid

struct MonthGridCard: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    let assignments: [Assignment]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    var body: some View {
        // Built once per render, not once per day cell, and not on every frame of a swipe: the
        // drag lives in `MonthPager`, so only the pager updates while a finger moves it.
        let dueByDay = Dictionary(grouping: assignments) { calendar.startOfDay(for: $0.dueDate) }
        let plannedDays = Set(assignments.filter { !$0.isCompleted }.compactMap(\.plannedDate).map { calendar.startOfDay(for: $0) })
        VStack(spacing: 12) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                Spacer()
                Button { step(-1) } label: { AppIcon(.back, size: 20).frame(width: 44, height: 44).contentShape(.rect) }
                    .accessibilityLabel("Previous month")
                Button { step(1) } label: { AppIcon(.forward, size: 20).frame(width: 44, height: 44).contentShape(.rect) }
                    .accessibilityLabel("Next month")
            }
            .buttonStyle(.pressable)
            .font(.body.weight(.semibold))

            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(weekdaySymbols.enumerated(), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 20)
                    }
                }
                .accessibilityHidden(true)

                MonthPager(
                    month: $month,
                    selected: calendar.startOfDay(for: selectedDay),
                    dueByDay: dueByDay,
                    plannedDays: plannedDays,
                    onSelect: select
                )
            }
        }
        .padding(16)
        // Sliding months disappear at the card's edge, not under its neighbours.
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .glassCard(cornerRadius: 26)
    }

    private var stepAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 1)
    }

    private func step(_ months: Int) {
        withAnimation(stepAnimation) {
            month = calendar.date(byAdding: .month, value: months, to: month)!
        }
    }

    private func select(_ day: Date) {
        withAnimation(stepAnimation) {
            selectedDay = day
            if !calendar.isDate(day, equalTo: month, toGranularity: .month) {
                month = calendar.dateInterval(of: .month, for: day)!.start
            }
        }
    }
}

/// The shown month with one each side, ready to be dragged in. It follows the finger 1:1, then
/// throws to wherever the swipe's momentum would carry it.
private struct MonthPager: View {
    @Binding var month: Date
    let selected: Date
    let dueByDay: [Date: [Assignment]]
    let plannedDays: Set<Date>
    let onSelect: (Date) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How far the finger has moved the months sideways, past the hysteresis.
    @State private var dragOffset: CGFloat = 0
    /// Set on a drag's first move, so a mostly vertical drag is left to the scroll view.
    @State private var dragAxis: Axis?
    @State private var pageWidth: CGFloat = 0

    private let calendar = Calendar.current
    /// Space between months while they slide, so the next one starts beyond the card's edge.
    private static let pageGap: CGFloat = 32
    /// Movement before a drag counts as a swipe; subtracted so the month doesn't jump on pickup.
    private static let hysteresis: CGFloat = 10

    /// Months are numbered from a fixed month, so stepping one month moves every page by one
    /// width and SwiftUI animates the strip as a whole.
    private static let anchor = Calendar.current.dateInterval(of: .month, for: Date(timeIntervalSinceReferenceDate: 0))!.start

    private var index: Int {
        calendar.dateComponents([.month], from: Self.anchor, to: month).month ?? 0
    }

    private func month(at index: Int) -> Date {
        calendar.date(byAdding: .month, value: index, to: Self.anchor)!
    }

    var body: some View {
        let index = index
        // Only the shown month sizes the pager; the neighbors hang off its top edge.
        ZStack(alignment: .top) {
            ForEach(index - 1...index + 1, id: \.self) { page in
                let isCurrent = page == index
                MonthDays(
                    month: month(at: page),
                    selected: selected,
                    dueByDay: dueByDay,
                    plannedDays: plannedDays,
                    onSelect: onSelect
                )
                .frame(height: isCurrent ? nil : 0, alignment: .top)
                .offset(x: reduceMotion ? 0 : CGFloat(page - index) * (pageWidth + Self.pageGap) + dragOffset)
                // Reduce Motion: months cross-fade in place instead of sliding.
                .opacity(reduceMotion && !isCurrent ? 0 : 1)
                .allowsHitTesting(isCurrent)
                .accessibilityHidden(!isCurrent)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
        .contentShape(.rect)
        .gesture(swipe)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: Self.hysteresis)
            .onChanged { value in
                if dragAxis == nil {
                    dragAxis = abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical
                }
                guard dragAxis == .horizontal, !reduceMotion else { return }
                let width = value.translation.width
                let tracked = width - min(Self.hysteresis, abs(width)) * (width < 0 ? -1 : 1)
                // A very short spring rather than none, so grabbing a month mid-slide picks it up
                // from where it is on screen instead of jumping.
                withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 1)) {
                    dragOffset = tracked
                }
            }
            .onEnded { value in
                defer { dragAxis = nil }
                guard dragAxis == .horizontal else { return }
                let velocity = value.velocity.width
                // Where the swipe would come to rest if thrown, as a scroll view decelerates.
                let projected = dragOffset + Momentum.project(velocity)
                let threshold = pageWidth / 2
                let months = projected < -threshold ? 1 : (projected > threshold ? -1 : 0)
                settle(byMonths: months, velocity: velocity)
            }
    }

    /// Lands on `months` away (or back where it was) and hands the finger's velocity to the spring,
    /// so there's no seam between dragging and animating.
    private func settle(byMonths months: Int, velocity: CGFloat) {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) {
                if months != 0 { month = month(at: index + months) }
                dragOffset = 0
            }
            return
        }
        // The shown page's on-screen offset goes from `dragOffset` to one page over (or to zero).
        let remaining = -CGFloat(months) * (pageWidth + Self.pageGap) - dragOffset
        let relativeVelocity = abs(remaining) > 1 ? velocity / remaining : 0
        // A little give only when the swipe was thrown; a slow drag settles without overshoot.
        let spring = abs(velocity) > 300 ? Spring(response: 0.4, dampingRatio: 0.85) : Spring(response: 0.4, dampingRatio: 1)
        withAnimation(.interpolatingSpring(spring, initialVelocity: relativeVelocity)) {
            if months != 0 { month = month(at: index + months) }
            dragOffset = 0
        }
    }
}

/// One month's day cells as whole weeks, starting on the locale's first weekday.
private struct MonthDays: View {
    let month: Date
    let selected: Date
    let dueByDay: [Date: [Assignment]]
    let plannedDays: Set<Date>
    let onSelect: (Date) -> Void

    private let calendar = Calendar.current

    private var days: [Date] {
        let leading = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: month)!.count
        let cells = Int(ceil(Double(leading + count) / 7)) * 7
        let start = calendar.date(byAdding: .day, value: -leading, to: month)!
        return (0..<cells).map { calendar.date(byAdding: .day, value: $0, to: start)! }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(days, id: \.self) { day in
                Button { onSelect(day) } label: {
                    DayCell(
                        day: day,
                        isInMonth: calendar.isDate(day, equalTo: month, toGranularity: .month),
                        isSelected: day == selected,
                        due: dueByDay[day] ?? [],
                        hasPlanned: plannedDays.contains(day)
                    )
                }
                .buttonStyle(.pressable(scale: 0.9))
            }
        }
    }
}

private struct DayCell: View {
    let day: Date
    let isInMonth: Bool
    let isSelected: Bool
    let due: [Assignment]
    let hasPlanned: Bool
    @Environment(\.currentTime) private var now

    private var isToday: Bool { Calendar.current.isDate(day, inSameDayAs: now) }
    private var isPast: Bool { day < Calendar.current.startOfDay(for: now) }

    var body: some View {
        VStack(spacing: 3) {
            Text(day.formatted(.dateTime.day()))
                .font(.subheadline.weight(isToday || isSelected ? .bold : .medium))
                .foregroundStyle(isToday ? Palette.onAccent : (isPast ? Palette.mutedNumber : Palette.text))
                .frame(width: 34, height: 34)
                .background {
                    if isToday { Circle().fill(Palette.accent) }
                }
                .overlay {
                    // The selected day (when it isn't today) gets an accent ring.
                    if isSelected, !isToday {
                        Circle().strokeBorder(Palette.accent, lineWidth: 2)
                    }
                }

            HStack(spacing: 3) {
                ForEach(due.prefix(3)) { assignment in
                    Circle()
                        .fill(assignment.tint.opacity(assignment.isCompleted ? 0.4 : 1))
                        .frame(width: 5, height: 5)
                }
                if hasPlanned {
                    Circle()
                        .strokeBorder(Palette.accent, lineWidth: 1.2)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .opacity(isInMonth ? 1 : 0.35)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        let open = due.count { !$0.isCompleted }
        if open > 0 { parts.append("\(open) due") }
        if hasPlanned { parts.append("work planned") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Day agenda

/// The selected day's items in one glass panel: what's due, then planned work sessions.
private struct DayAgenda: View {
    let day: Date
    let assignments: [Assignment]
    @Environment(\.currentTime) private var now

    private let calendar = Calendar.current

    private var range: Range<Date> {
        let start = calendar.startOfDay(for: day)
        return start..<calendar.date(byAdding: .day, value: 1, to: start)!
    }

    private var title: String {
        calendar.isDate(day, inSameDayAs: now) ? "Today" : day.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        let range = range
        let due = assignments.filter { range.contains($0.dueDate) }
        let planned = assignments.filter {
            !$0.isCompleted && $0.plannedDate.map(range.contains) == true && !range.contains($0.dueDate)
        }
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title)
                Spacer()
                let open = due.count { !$0.isCompleted }
                if !due.isEmpty {
                    Text(open == 0 ? "All done" : "\(open) left")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.trailing, 4)
                }
            }

            if due.isEmpty && planned.isEmpty {
                Text("Nothing due or planned. A good day to get ahead.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    .glassCard(cornerRadius: 26)
            } else {
                let plannedIDs = Set(planned.map(\.id))
                AssignmentGroup(assignments: due + planned) { plannedIDs.contains($0.id) ? "Planned" : nil }
            }
        }
    }
}
