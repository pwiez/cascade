import CascadeEngine
import SwiftUI

struct TimeScaleSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section("Simulation Speed") {
            VStack(spacing: 8) {
                LabeledContent("Time Scale") {
                    Text(simulation.settings.timeScale.formatted(.number.precision(.fractionLength(1))) + "x")
                        .monospacedDigit()
                }
                Slider(value: $simulation.settings.timeScale, in: SimSettings.timeScaleRange) {
                    Text("Time Scale")
                } minimumValueLabel: {
                    Image(systemName: "tortoise.fill").accessibilityHidden(true)
                } maximumValueLabel: {
                    Image(systemName: "hare.fill").accessibilityHidden(true)
                }
            }
            .padding(.vertical, 3)
        }
    }
}
