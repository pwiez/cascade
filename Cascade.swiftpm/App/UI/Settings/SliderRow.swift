import CascadeEngine
import SwiftUI

/// A labelled slider with a live value readout, and an optional badge marking
/// changes that only take effect after a restart.
struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var step: Double?

    /// Decimal places in the readout. Formatting goes through `FormatStyle`
    /// rather than a printf pattern so the decimal separator follows the user's
    /// locale — "1,5" where that is what the rest of the system says.
    var fractionDigits = 1

    /// Appended verbatim after the number, e.g. "x" or " Units".
    var unit = ""

    /// Prepended verbatim, e.g. "±".
    var prefix = ""

    var requiresRestart = false
    var caption: String?

    private var formatted: String {
        prefix + value.formatted(.number.precision(.fractionLength(fractionDigits))) + unit
    }

    var body: some View {
        VStack(spacing: 4) {
            LabeledContent(label) {
                HStack(spacing: 6) {
                    if requiresRestart {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .imageScale(.small)
                            .accessibilityHidden(true)
                    }
                    Text(formatted)
                        .monospacedDigit()
                }
                .font(.caption.bold())
                .foregroundStyle(requiresRestart ? .yellow : .secondary)
                .animation(.snappy, value: requiresRestart)
            }

            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(formatted)
        .accessibilityHint(accessibilityHintText)
    }

    private var accessibilityHintText: String {
        let restartNote = requiresRestart ? "Takes effect after restarting the simulation." : ""
        return [caption, restartNote].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
