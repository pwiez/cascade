import SwiftUI

/// A hairline-separated card: icon, title, then prose.
///
/// Used for both the engine's simplifications and the remediation strategies —
/// they were separate types with byte-identical bodies.
struct IconCard: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(DesignTokens.hairline)
                .frame(height: 1)

            Label(title, systemImage: icon)
                .font(.headline)
                .labelStyle(IconCardLabelStyle())

            Text(description)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Tints the icon to the accent colour and gives it a fixed column so titles
/// line up down the page.
private struct IconCardLabelStyle: LabelStyle {
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
