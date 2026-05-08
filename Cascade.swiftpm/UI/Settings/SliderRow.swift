import SwiftUI

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var format: String = "%.1f"
    var requiresRestart: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            LabeledContent(label) {
                HStack(spacing: 6) {
                    if requiresRestart {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2.weight(.bold))
                            .imageScale(.small)
                    }
                    Text(String(format: format, value))
                        .monospacedDigit()
                }
                .foregroundStyle(requiresRestart ? .yellow : .secondary)
                .animation(.snappy, value: requiresRestart)
            }

            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel(label)
        .accessibilityValue(String(format: format, value))
    }
}
