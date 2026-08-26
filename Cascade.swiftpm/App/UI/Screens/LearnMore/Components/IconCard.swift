//
//  IconCard.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct IconCard: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(DesignTokens.hairline)
                .frame(height: 1)

            Label(title, systemImage: icon)
                .font(.headline)
                .labelStyle(IconCardLabelStyle())

            Text(description)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct IconCardLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .font(.callout)
                .foregroundStyle(DesignTokens.signal)
                .frame(width: 22)
            configuration.title
        }
    }
}
