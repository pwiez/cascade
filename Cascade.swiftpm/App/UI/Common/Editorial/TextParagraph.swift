//
//  TextParagraph.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct TextParagraph: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        Text(text)
            .font(.body)
            .lineSpacing(DesignTokens.bodyLineSpacing)
            .foregroundStyle(DesignTokens.bodyText)
            .fixedSize(horizontal: false, vertical: true)
    }
}
