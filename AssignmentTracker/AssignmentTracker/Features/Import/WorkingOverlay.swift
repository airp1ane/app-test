import SwiftUI

struct WorkingOverlay: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: 280)
        .glassCard(cornerRadius: 28)
        .accessibilityElement(children: .combine)
    }
}
