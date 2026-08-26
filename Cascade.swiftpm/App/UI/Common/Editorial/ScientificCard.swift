//
//  ScientificCard.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct ScientificCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.vertical, DesignTokens.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.dataSurface)
            .overlay(alignment: .top) { rule }
            .overlay(alignment: .bottom) { rule }
    }

    private var rule: some View {
        Rectangle()
            .fill(DesignTokens.ruleStrong)
            .frame(height: 1)
    }
}
