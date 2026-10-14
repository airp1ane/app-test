import PhotosUI
import SwiftUI
import VisionKit

/// Where the syllabus comes from: a file, photos, or a scan (on devices with a camera). Dimmed
/// until a class is picked.
struct SyllabusSourceCard: View {
    @Binding var photoSelection: [PhotosPickerItem]
    let isEnabled: Bool
    let onChooseFile: () -> Void
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SourceRow(title: "Choose File", icon: .notes, action: onChooseFile)
            Divider()
            PhotosPicker(selection: $photoSelection, maxSelectionCount: 10, matching: .images) {
                // No photo glyph in the app's icon set; SF Symbol fallback.
                SourceRowLabel(title: "Photo Library", fallbackSymbol: "photo.on.rectangle")
            }
            .buttonStyle(.pressable)
            if VNDocumentCameraViewController.isSupported {
                Divider()
                SourceRow(title: "Scan Document", icon: .scan, action: onScan)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassCard()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}
