import SwiftUI

/// Body copy in a chapter. Takes a `LocalizedStringKey` so markdown emphasis in
/// the source text renders.
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
