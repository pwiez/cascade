import SwiftUI

/// Prompts the reader to go try something in the simulation.
struct TryThisBox: View {
    let instruction: String

    var body: some View {
        RuledCallout(label: "Try It", accent: DesignTokens.signal, labelColor: DesignTokens.signal) {
            Text(instruction)
                .font(.body)
                .foregroundStyle(DesignTokens.bodyText)
                .lineSpacing(DesignTokens.bodyLineSpacing)
        }
    }
}
