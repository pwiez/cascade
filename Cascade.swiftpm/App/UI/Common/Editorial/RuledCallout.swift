//
//  RuledCallout.swift
//  Cascade
//
//  Created by Pedro Wiezel on 27/05/26.
//

import SwiftUI

struct RuledCallout<Content: View>: View {
    let label: String
    var accent: Color = DesignTokens.ruleStrong
    var labelColor: Color = DesignTokens.dimText

    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Capsule()
                .fill(accent)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: label, color: labelColor)
                content
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .combine)
    }
}
