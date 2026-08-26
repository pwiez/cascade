import SwiftUI

/// Second onboarding page: what each control does.
struct ControlsPage: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Controls")
                .font(.system(size: titleSize, weight: .bold))

            HStack(alignment: .top, spacing: 56) {
                ControlColumn(items: ControlItem.simulationControls)
                ControlColumn(items: ControlItem.cameraControls)
            }
            .padding(.vertical, 32)
        }
    }
}
