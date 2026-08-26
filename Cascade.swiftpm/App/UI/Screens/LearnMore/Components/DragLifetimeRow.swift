//
//  DragLifetimeRow.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct DragLifetimeRow: View {
    let altitude: String
    let lifetime: String

    let intensity: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(altitude)
                .font(.caption.weight(.semibold).monospacedDigit())
                .frame(width: 70, alignment: .leading)

            ProgressView(value: intensity)
                .progressViewStyle(.linear)
                .tint(color.opacity(0.6))
                .frame(height: DesignTokens.trackHeight)

            Text(lifetime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DesignTokens.mutedText)
                .frame(width: 120, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("At \(altitude), debris lifetime is approximately \(lifetime)")
    }
}
