import SwiftUI

/// A highlighted explanation of one idea.
struct KeyConceptBox: View {
    let title: String
    let bodyText: String
    let icon: String

    var body: some View {
        RuledCallout(label: "Key Concept") {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
    }
}
