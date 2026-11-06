import SwiftUI

/// An import item's type, optional due date and time, and grade weight.
struct CandidateDetailsCard: View {
    @Binding var draft: ImportCandidate
    @Binding var hasDate: Bool
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RowLabel("Type", icon: draft.kind.icon)
                Spacer()
                // Outside a Form a menu picker shows only its button, so label it here.
                Picker("Type", selection: $draft.kind) {
                    ForEach(AssignmentKind.allCases) { kind in
                        Label(kind.label, appIcon: kind.icon).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .frame(minHeight: 52)

            Divider()
            Toggle(isOn: $hasDate.animation(.snappy)) {
                RowLabel("Due date", icon: .calendar)
            }
            .tint(Palette.onTimeGreen)
            .frame(minHeight: 52)

            if hasDate {
                Divider()
                DatePicker(selection: $date, displayedComponents: .date) {
                    RowLabel("Day", icon: .calendar)
                }
                .frame(minHeight: 52)
                Divider()
                DatePicker(selection: $date, displayedComponents: .hourAndMinute) {
                    RowLabel("Time", icon: .clock)
                }
                .frame(minHeight: 52)
            }

            Divider()
            HStack {
                RowLabel("Weight", icon: .badge)
                TextField("e.g. 15%", text: $draft.weightText)
                    .multilineTextAlignment(.trailing)
            }
            .frame(minHeight: 52)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassCard()
    }
}
