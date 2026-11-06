import SwiftUI

struct BadgesSummary: View {
    let stats: HabitStats

    var body: some View {
        let earned = stats.badges.count(where: \.isUnlocked)
        let recent = stats.mostRecentEarned
        let next = stats.nextToEarn
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader("Badges")
                Spacer()
                NavigationLink(value: StreaksRoute.badges) {
                    Text("\(earned) of \(stats.badges.count) · See all")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.accentText)
                        .frame(minHeight: 44)
                }
                .padding(.trailing, 4)
            }

            GlassGroup {
                if let recent {
                    BadgeRow(badge: recent)
                }
                if recent != nil, next != nil {
                    InsetDivider()
                }
                if let next {
                    BadgeRow(badge: next)
                }
            }
        }
    }
}
