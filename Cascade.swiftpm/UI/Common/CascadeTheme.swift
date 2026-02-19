//
//  CascadeTheme.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

enum CascadeTheme {
    
    static let cardRadius: CGFloat = 16
    static let innerRadius: CGFloat = 12
    static let badgeRadius: CGFloat = 6
    
    static let cardPadding: CGFloat = 20
    static let compactPadding: CGFloat = 16
    static let iconSize: CGFloat = 40
    static let iconRadius: CGFloat = 10
    
    static let cardBackground = Color(white: 0.08)
    static let raisedBackground = Color(white: 0.10)
    static let tintedBackgroundOpacity: Double = 0.06
    
    static let cardBorder = Color.white.opacity(0.06)
    static let accentBorderOpacity: Double = 0.12
    static let borderWidth: CGFloat = 1
    
    static let dividerColor = Color.white.opacity(0.08)
    
    static let bodyText = Color(white: 0.82)
    static let dimText = Color(white: 0.55)
    static let mutedText = Color.gray
    
    static let bodyLineSpacing: CGFloat = 5
    static let compactLineSpacing: CGFloat = 3
    
    static let iconBackgroundOpacity: Double = 0.12
    
    static let trackColor = Color(white: 0.12)
    static let trackHeight: CGFloat = 4
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = CascadeTheme.cardPadding
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CascadeTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                    .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
            )
    }
}

struct AccentCardStyle: ViewModifier {
    let accent: Color
    var padding: CGFloat = CascadeTheme.cardPadding
    var radius: CGFloat = CascadeTheme.cardRadius
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(CascadeTheme.tintedBackgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(accent.opacity(CascadeTheme.accentBorderOpacity), lineWidth: CascadeTheme.borderWidth)
            )
    }
}

struct InnerCardStyle: ViewModifier {
    var accent: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .padding(CascadeTheme.compactPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent?.opacity(CascadeTheme.tintedBackgroundOpacity) ?? Color(CascadeTheme.cardBackground))
            .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.innerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CascadeTheme.innerRadius)
                    .stroke(
                        accent?.opacity(CascadeTheme.accentBorderOpacity) ?? CascadeTheme.cardBorder,
                        lineWidth: CascadeTheme.borderWidth
                    )
            )
    }
}

extension View {
    func cascadeCard(padding: CGFloat = CascadeTheme.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
    }
    
    func cascadeAccentCard(_ accent: Color, padding: CGFloat = CascadeTheme.cardPadding, radius: CGFloat = CascadeTheme.cardRadius) -> some View {
        modifier(AccentCardStyle(accent: accent, padding: padding, radius: radius))
    }
    
    func cascadeInnerCard(accent: Color? = nil) -> some View {
        modifier(InnerCardStyle(accent: accent))
    }
    
    func cascadeDivider() -> some View {
        self.overlay(CascadeTheme.dividerColor)
    }
}

struct ThemedIcon: View {
    let systemName: String
    let color: Color
    var size: CGFloat = CascadeTheme.iconSize
    var shape: IconShape = .roundedRect
    
    enum IconShape {
        case circle, roundedRect
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(CascadeTheme.iconBackgroundOpacity))
            .clipShape(shape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: CascadeTheme.iconRadius)))
    }
}
