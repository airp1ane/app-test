import SwiftUI

/// All course colors as large, tappable swatches.
struct ColorGrid: View {
    @Binding var selection: CourseColor

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CourseColor.allCases, id: \.self) { option in
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: 38, height: 38)
                        .overlay {
                            if option == selection {
                                AppIcon(.check, size: 14, weight: 3)
                                    .foregroundStyle(Palette.onAccent)
                            }
                        }
                        .padding(3)
                        .overlay {
                            if option == selection {
                                Circle().strokeBorder(option.color, lineWidth: 2)
                            }
                        }
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 24)
    }
}
