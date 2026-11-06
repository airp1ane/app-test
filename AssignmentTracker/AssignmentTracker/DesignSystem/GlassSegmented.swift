import SwiftUI

/// A segmented control for filters and modes: the system one, so the selection is the real
/// Liquid Glass thumb that lifts, stretches and can be dragged between segments.
struct GlassSegmented<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        Picker(selection: $selection.animation(.snappy)) {
            ForEach(options, id: \.value) { option in
                Text(option.label).tag(option.value)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
    }
}
