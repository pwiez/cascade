//
//  DesignTokens.swift
//  Cascade
//
//  Created by Pedro Wiezel on 17/02/26.
//

import SwiftUI

/// The app's shared visual constants.
///
/// Cascade forces dark mode, so these are absolute values rather than
/// semantic ones. Anything the system *can* adapt — body copy, secondary
/// labels — still uses `.primary` and `.secondary`; these cover the cases where
/// a specific value in a specific dark palette is the point.
enum DesignTokens {

    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20

    // Text
    static let bodyText = Color(white: 0.82)
    static let dimText = Color(white: 0.55)
    static let mutedText = Color.gray
    static let ink = Color(white: 0.92)
    static let bodyLineSpacing: CGFloat = 5

    // Rules and surfaces, lightest to heaviest
    static let hairline = Color.white.opacity(0.12)
    static let ruleStrong = Color.white.opacity(0.22)
    static let dividerColor = Color.white.opacity(0.20)
    static let dataSurface = Color.white.opacity(0.022)
    static let sidebarBackground = Color(white: 0.07)
    static let chapterBackground = Color.black

    // Accent
    static let signal = Color.blue
    static let iconBackgroundOpacity: Double = 0.12

    // Progress tracks
    static let trackColor = Color(white: 0.12)
    static let trackHeight: CGFloat = 4
}

extension View {
    /// Tints a `Divider` to the app's rule colour.
    func cascadeDivider() -> some View {
        overlay(DesignTokens.dividerColor)
    }
}

extension View {
    /// Liquid Glass where the OS has it, materials where it doesn't.
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
