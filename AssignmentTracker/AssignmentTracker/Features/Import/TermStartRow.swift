import SwiftUI

/// When classes start, which places "Week N" dates. A date picker once it's set; until then a
/// button that sets it.
struct TermStartRow: View {
    let model: SyllabusImportModel

    var body: some View {
        if let termStart = model.termStart {
            // `termStart` is optional; the picker edits it only once it has a value.
            DatePicker(selection: Binding(get: { termStart }, set: { model.termStart = $0 }), displayedComponents: .date) {
                VStack(alignment: .leading, spacing: 2) {
                    RowLabel("Classes start", icon: .calendar)
                    Text("Places dates like “Week 3, Friday”")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.leading, 36)
                }
            }
            .frame(minHeight: 52)
        } else {
            Button(action: setTermStart) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        RowLabel("Set when classes start", icon: .plan)
                        Text(model.usesRelativeWeeks
                             ? "Needed for dates like “Week 3, Friday”"
                             : "The syllabus doesn’t say")
                            .font(.caption)
                            .foregroundStyle(model.usesRelativeWeeks ? Palette.warning : Palette.secondaryText)
                            .padding(.leading, 36)
                    }
                    Spacer()
                }
                .frame(minHeight: 52)
                .contentShape(.rect)
            }
            .buttonStyle(.pressable)
        }
    }

    private func setTermStart() {
        model.termStart = model.startOfReferenceDay
    }
}
