import SwiftUI

/// A small-caps label above a heading or callout.
struct Kicker: View {
    let text: String
    var color: Color = DesignTokens.dimText

    var body: some View {
        Text(text)
            .font(.footnote.smallCaps().weight(.semibold))
            .tracking(1.0)
            .foregroundStyle(color)
    }
}
