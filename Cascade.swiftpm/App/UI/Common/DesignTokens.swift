//
//  DesignTokens.swift
//  Cascade
//
//  Created by Pedro Wiezel on 17/02/26.
//

import SwiftUI

enum DesignTokens {

    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20

    static let bodyText = Color(white: 0.82)
    static let dimText = Color(white: 0.55)
    static let mutedText = Color.gray
    static let ink = Color(white: 0.92)
    static let bodyLineSpacing: CGFloat = 5

    static let hairline = Color.white.opacity(0.12)
    static let ruleStrong = Color.white.opacity(0.22)
    static let dividerColor = Color.white.opacity(0.20)
    static let dataSurface = Color.white.opacity(0.022)
    static let sidebarBackground = Color(white: 0.07)
    static let chapterBackground = Color.black

    static let signal = Color.blue
    static let iconBackgroundOpacity: Double = 0.12

    static let trackColor = Color(white: 0.12)
    static let trackHeight: CGFloat = 4
}

extension View {
    func cascadeDivider() -> some View {
        overlay(DesignTokens.dividerColor)
    }
}

extension View {
    @ViewBuilder
    func applyGlassStyle(isProminent: Bool, tint: Color?) -> some View {
        if #available(iOS 26, *) {
            if isProminent {
                buttonStyle(.glassProminent).tint(tint)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if isProminent {
                buttonStyle(.borderedProminent).tint(tint)
            } else {
                buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    func applyGlassPanel() -> some View {
        if #available(iOS 26, *) {
            glassEffect()
        } else {
            background(.ultraThinMaterial, in: .capsule)
        }
    }
}
