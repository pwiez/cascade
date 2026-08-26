//
//  TimelineRow.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct TimelineRow: View {
    let event: TimelineEvent

    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(DesignTokens.signal)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)

                if !isLast {
                    Rectangle()
                        .fill(DesignTokens.hairline)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .frame(width: 12)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.date)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.dimText)
                Text(event.title)
                    .font(.headline)
                Text(event.summary)
                    .font(.body)
                    .foregroundStyle(DesignTokens.bodyText)
                    .lineSpacing(DesignTokens.bodyLineSpacing)
                    .padding(.bottom, 30)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.date). \(event.title). \(event.summary)")
    }
}
