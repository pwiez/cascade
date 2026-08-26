import SwiftUI

/// A large figure with its unit and a caption, used for orbital statistics.
struct OperationalStatCard: View {
    let value: String
    let unit: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(accent)
                .frame(width: 32, height: 2)
                .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.largeTitle.bold().monospacedDigit())
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DesignTokens.mutedText)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(DesignTokens.mutedText)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(unit): \(label)")
    }
}
