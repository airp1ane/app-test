import SwiftUI

/// Motivation: the on-time streak and stats, this week's progress, and badges to unlock.
struct StreaksView: View {
    let stats: HabitStats

    @State private var isShowingInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(subtitle: "Best streak: \(stats.bestStreak)", title: "Streaks") {
                        GlassCircleButton(icon: .info, label: "How streaks work") {
                            isShowingInfo = true
                        }
                    }

                    StreakCard(stats: stats)
                    ThisWeekCard(stats: stats)
                    BadgesSummary(stats: stats)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background { DuskBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingInfo) { StreakInfoSheet() }
            .navigationDestination(for: StreaksRoute.self) { route in
                switch route {
                case .badges: BadgesView(stats: stats)
                }
            }
        }
    }
}

#Preview {
    StreaksView(stats: HabitStats())
}
