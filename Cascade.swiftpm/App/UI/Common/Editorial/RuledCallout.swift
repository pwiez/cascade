import SwiftUI

/// A labelled aside set off by a vertical rule.
struct RuledCallout<Content: View>: View {
    let label: String
    var accent: Color = DesignTokens.ruleStrong
    var labelColor: Color = DesignTokens.dimText

    /// Stored as a built view rather than a closure: the initialiser's builder
    /// runs once at construction instead of on every body evaluation.
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Capsule()
                .fill(accent)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: label, color: labelColor)
                content
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .combine)
    }
}
