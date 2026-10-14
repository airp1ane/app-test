import SwiftUI

/// How the items were found: the on-device model, or pattern matching and why.
struct DetectionEngineRow: View {
    let engine: DetectionEngine

    var body: some View {
        switch engine {
        case .onDeviceModel:
            // No Apple Intelligence glyph in the app's icon set; SF Symbol fallback.
            Label("Found with Apple Intelligence, on this iPhone", systemImage: "apple.intelligence")
                .font(.footnote)
        case .rules(let reason):
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Found with basic pattern matching")
                    if let reason {
                        Text("\(reason). Check the list carefully.")
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            } icon: {
                AppIcon(.search, size: 18)
            }
            .font(.footnote)
        }
    }
}
