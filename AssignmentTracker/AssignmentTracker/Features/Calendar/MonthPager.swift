import SwiftUI

/// The shown month with one each side, ready to be dragged in. It follows the finger 1:1, then
/// throws to wherever the swipe's momentum would carry it.
struct MonthPager: View {
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

    @Environment(\.calendar) private var calendar
    /// Space between months while they slide, so the next one starts beyond the card's edge.
    private static let pageGap: CGFloat = 32
    /// Movement before a drag counts as a swipe; subtracted so the month doesn't jump on pickup.
    private static let hysteresis: CGFloat = 10

    /// Months are numbered from a fixed month, so stepping one month moves every page by one
    /// width and SwiftUI animates the strip as a whole.
    private static let anchor = Calendar.current.start(of: .month, for: Date(timeIntervalSinceReferenceDate: 0))

    private var index: Int {
        calendar.dateComponents([.month], from: Self.anchor, to: month).month ?? 0
    }

    private func month(at index: Int) -> Date {
        calendar.adding(.month, index, to: Self.anchor)
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
