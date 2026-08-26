//
//  DefinitionCallout.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct DefinitionCallout: View {
    let term: String
    let definition: String
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Kicker(text: "Definition", color: DesignTokens.signal)

            Text(term)
                .font(.title.bold())

            Text(definition)
                .font(.title3)
                .foregroundStyle(DesignTokens.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(source)")
                .font(.caption.italic())
                .foregroundStyle(DesignTokens.mutedText)
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }
}
