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
        RuledCallout(label: "Try It", accent: DesignTokens.signal, labelColor: DesignTokens.signal) {
            Text(instruction)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
    }
}
