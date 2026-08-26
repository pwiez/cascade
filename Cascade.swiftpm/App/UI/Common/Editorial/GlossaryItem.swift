//
//  GlossaryItem.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/02/26.
//

import SwiftUI

struct GlossaryItem: View {
    let term: String
    let definition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(DesignTokens.hairline)
                .frame(height: 1)

            Text(term)
                .font(.headline)

            Text(definition)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
        .accessibilityElement(children: .combine)
    }
}
