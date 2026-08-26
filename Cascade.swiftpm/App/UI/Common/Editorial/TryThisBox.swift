//
//  TryThisBox.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/02/26.
//

import SwiftUI

struct TryThisBox: View {
    let instruction: String

    var body: some View {
        RuledCallout(accent: DesignTokens.signal) {
            Label("Try it", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(DesignTokens.signal)

            Text(instruction)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
    }
}
