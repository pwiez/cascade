//
//  IconCardLabelStyle.swift
//  Cascade
//

import SwiftUI

struct IconCardLabelStyle: LabelStyle {
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
