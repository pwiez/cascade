//
//  ModelParam.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct ModelParam: View {
    let name: String
    let value: String
    let detail: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.mutedText)
            }
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(DesignTokens.signal)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
