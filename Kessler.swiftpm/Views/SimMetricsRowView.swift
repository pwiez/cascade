import SwiftUI

struct SimMetricsRow: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            Spacer()
            if #available(iOS 17.0, *) {
                Text("\(value)")
                    .font(.body.monospacedDigit())
                    .bold()
                    .contentTransition(.numericText(value: Double(value)))
                    .animation(.snappy, value: value)
            } else {
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
