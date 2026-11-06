import SwiftUI

/// The editor's type, due date, time and reminder rows. Turning the reminder on asks for
/// notification permission, and links to Settings when it has been turned off.
struct AssignmentScheduleCard: View {
    @Binding var kind: AssignmentKind
    @Binding var dueDate: Date
    @Binding var remindDayBefore: Bool
    @Binding var notificationsBlocked: Bool

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RowLabel("Type", icon: kind.icon)
                Spacer()
                Picker("Type", selection: $kind) {
                    ForEach(AssignmentKind.allCases) { Label($0.label, appIcon: $0.icon).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .frame(minHeight: 52)

            Divider()

            DatePicker(selection: $dueDate, displayedComponents: .date) {
                RowLabel("Due date", icon: .calendar)
            }
            .frame(minHeight: 52)

            Divider()

            DatePicker(selection: $dueDate, displayedComponents: .hourAndMinute) {
                RowLabel("Time", icon: .clock)
            }
            .frame(minHeight: 52)

            Divider()

            Toggle(isOn: $remindDayBefore) {
                RowLabel("Remind me a day before", icon: .reminder)
            }
            .tint(Palette.onTimeGreen)
            .frame(minHeight: 52)
            .onChange(of: remindDayBefore) { _, isOn in
                reminderChanged(isOn)
            }

            if notificationsBlocked && remindDayBefore {
                Button(action: openSettings) {
                    Label { Text("Notifications are off for this app. Turn them on in Settings.") } icon: { AppIcon(.reminder, size: 16) }
                        .font(.footnote)
                        .foregroundStyle(Palette.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassCard()
    }

    private func reminderChanged(_ isOn: Bool) {
        guard isOn else { notificationsBlocked = false; return }
        Task { notificationsBlocked = !(await ReminderScheduler.requestAuthorization()) }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}
