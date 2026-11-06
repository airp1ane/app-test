import SwiftUI

struct SourceRow: View {
    let title: String
    let icon: AppIcon.Name
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SourceRowLabel(title: title, icon: icon)
        }
        .buttonStyle(.pressable)
    }
}
