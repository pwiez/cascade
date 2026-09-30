//
//  SliderRow.swift
//  Cascade
//
//  Created by Pedro Wiezel on 08/05/26.
//

import SwiftUI

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var step: Double?

    var fractionDigits = 1

    var unit = ""

    var prefix = ""

    var requiresRestart = false
    var caption: String?

    var body: some View {
        let formattedValue = prefix + value.formatted(.number.precision(.fractionLength(fractionDigits))) + unit

        VStack(spacing: 4) {
            LabeledContent(label) {
                HStack(spacing: 6) {
                    if requiresRestart {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .imageScale(.small)
                            .accessibilityHidden(true)
                    }
                    Text(formattedValue)
                        .monospacedDigit()
                }
                .font(.caption.bold())
                .foregroundStyle(requiresRestart ? .yellow : .secondary)
                .animation(.snappy, value: requiresRestart)
            }
            .accessibilityHidden(true)

            slider(formattedValue: formattedValue)

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
    }

    private func slider(formattedValue: String) -> some View {
        Group {
            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }
        }
        .accessibilityIdentifier("settings.slider.\(label)")
        .accessibilityLabel(label)
        .accessibilityValue(formattedValue)
        .accessibilityHint(accessibilityHintText)
    }

    private var accessibilityHintText: String {
        let restartNote = requiresRestart ? "Takes effect after restarting the simulation." : ""
        return [caption, restartNote].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
