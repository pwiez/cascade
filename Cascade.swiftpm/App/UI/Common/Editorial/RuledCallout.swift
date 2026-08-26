//
//  RuledCallout.swift
//  Cascade
//
//  Created by Pedro Wiezel on 27/05/26.
//

import SwiftUI

struct RuledCallout<Content: View>: View {
    var accent: Color = DesignTokens.ruleStrong

    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Capsule()
                .fill(accent)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .combine)
    }
}
