import SwiftUI

/// One timeline entry: a dot, the connecting rule, and the event's text.
struct TimelineRow: View {
    let event: TimelineEvent

    /// The last row draws no connector, so the timeline ends on its dot.
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(DesignTokens.signal)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)

                if !isLast {
                    Rectangle()
                        .fill(DesignTokens.hairline)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .frame(width: 12)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Kicker(text: event.date)
                Text(event.title)
                    .font(.headline)
                Text(event.summary)
                    .font(.body)
                    .foregroundStyle(DesignTokens.bodyText)
                    .lineSpacing(DesignTokens.bodyLineSpacing)
                    .padding(.bottom, 30)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.date). \(event.title). \(event.summary)")
    }
}
