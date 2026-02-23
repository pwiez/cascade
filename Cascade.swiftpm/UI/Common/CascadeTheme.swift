import SwiftUI

enum CascadeTheme {
    static let cardRadius: CGFloat = 16
    static let iconRadius: CGFloat = 10
    
    static let cardPadding: CGFloat = 20
    static let compactPadding: CGFloat = 16
    static let iconSize: CGFloat = 40
    
    static let cardBackground = Color(white: 0.08)
    static let tintedBackgroundOpacity: Double = 0.06
    
    static let cardBorder = Color.white.opacity(0.06)
    static let accentBorderOpacity: Double = 0.12
    static let borderWidth: CGFloat = 1
    
    static let dividerColor = Color.white.opacity(0.08)
    
    static let bodyText = Color(white: 0.82)
    static let dimText = Color(white: 0.55)
    static let mutedText = Color.gray
    
    static let bodyLineSpacing: CGFloat = 5
    
    static let iconBackgroundOpacity: Double = 0.12
    
    static let trackColor = Color(white: 0.12)
    static let trackHeight: CGFloat = 4
}

extension View {
    func cascadeDivider() -> some View {
        self.overlay(CascadeTheme.dividerColor)
    }
}
