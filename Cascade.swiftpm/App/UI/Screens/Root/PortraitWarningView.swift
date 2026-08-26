import SwiftUI

/// Covers the app when the iPad is held in portrait, which the simulation's
/// side-by-side layout has no room for.
struct PortraitWarningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 80

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "ipad.landscape")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                    .accessibilityHidden(true)

                Text("Please Rotate Your Device")
                    .font(.title.bold())

                Text("Cascade is designed to be experienced in landscape mode.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
