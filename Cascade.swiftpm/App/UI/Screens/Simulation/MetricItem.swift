//
//  MetricItem.swift
//  Cascade
//
//  Created by Pedro Wiezel on 16/02/26.
//

import SwiftUI

struct MetricItem: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        let formattedValue = value.formatted()

        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)

            Text(formattedValue)
                .font(.body.bold())
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.localizedCapitalized)
        .accessibilityValue(formattedValue)
    }
}
