import SwiftUI

/// The top of the review screen: what was read, how items were found, when classes start and
/// whether to add reminders.
struct ImportSummaryCard: View {
    @Bindable var model: SyllabusImportModel
    let notificationsBlocked: Bool

    private var sourceDetail: String {
        var parts = ["\(model.candidates.count) found", "\(model.includedCount) selected"]
        if model.undatedCount > 0 { parts.append("\(model.undatedCount) need a date") }
        if model.pageCount > 1 { parts.append("\(model.pageCount) pages") }
        if model.recognizedPageCount > 0 {
            parts.append(model.recognizedPageCount == model.pageCount ? "text recognized from image" : "\(model.recognizedPageCount) scanned pages recognized")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                AppIcon(.notes, size: 22)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.sourceName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(sourceDetail)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .padding(.vertical, 12)

            Divider()
            DetectionEngineRow(engine: model.engine)
                .padding(.vertical, 12)

            if model.alreadyImported {
                Divider()
                Label {
                    Text("You’ve imported this syllabus into \(model.course?.name ?? "this class") before. Items already in the class are unchecked.")
                } icon: {
                    AppIcon(.info, size: 18).foregroundStyle(Palette.warning)
                }
                .font(.footnote)
                .padding(.vertical, 12)
            }

            Divider()
            TermStartRow(model: model)
                .padding(.vertical, 6)

            Divider()
            Toggle(isOn: $model.remindDayBefore) {
                RowLabel("Remind me a day before", icon: .reminder)
            }
            .tint(Palette.onTimeGreen)
            .frame(minHeight: 52)
            if model.remindDayBefore && notificationsBlocked {
                Text("Notifications are off for this app, so reminders won’t appear. Turn them on in Settings.")
                    .font(.footnote)
                    .foregroundStyle(Palette.warning)
                    .padding(.bottom, 10)
            }
        }
        .padding(.horizontal, 16)
        .glassCard()
    }
}
