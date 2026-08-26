import SwiftUI

/// A hairline-separated list of control rows.
struct ControlColumn: View {
    let items: [ControlItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index != 0 {
                    Divider().overlay(DesignTokens.hairline)
                }
                ControlRow(item: item)
                    .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
