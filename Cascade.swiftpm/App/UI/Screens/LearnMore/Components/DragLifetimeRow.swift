import SwiftUI

/// How long debris survives at one altitude, with a bar showing relative drag.
///
/// The bar is a `ProgressView` rather than a hand-measured rectangle: it needs no
/// `GeometryReader`, and it carries its own value to VoiceOver.
struct DragLifetimeRow: View {
    let altitude: String
    let lifetime: String

    /// Drag strength at this altitude, 0...1, relative to the lowest orbit shown.
    let intensity: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(altitude)
                .font(.caption.weight(.semibold).monospacedDigit())
                .frame(width: 70, alignment: .leading)

            ProgressView(value: intensity)
                .progressViewStyle(.linear)
                .tint(color.opacity(0.6))
                .frame(height: DesignTokens.trackHeight)

            Text(lifetime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DesignTokens.mutedText)
                .frame(width: 120, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("At \(altitude), debris lifetime is approximately \(lifetime)")
    }
}
