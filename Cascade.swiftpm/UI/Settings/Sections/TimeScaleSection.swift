import SwiftUI

struct TimeScaleSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section {
            VStack(spacing: 8) {
                LabeledContent("Time Scale", value: String(format: "%.1fx", simulation.timeScale))
                Slider(value: $simulation.timeScale, in: 0.1...5.0) {
                    Text("Time Scale")
                } minimumValueLabel: {
                    Image(systemName: "tortoise.fill")
                } maximumValueLabel: {
                    Image(systemName: "hare.fill")
                }
            }
            .padding(.vertical, 3)
        } header: {
            Text("Simulation Speed")
        }
    }
}
