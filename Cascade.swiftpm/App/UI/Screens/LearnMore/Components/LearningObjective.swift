//
//  LearningObjective.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct LearningObjective: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(DesignTokens.signal)
                .frame(width: 14, height: 2)
                .padding(.top, 9)
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(3)
        }
        .accessibilityElement(children: .combine)
    }
}
