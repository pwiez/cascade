import SwiftUI

struct SpreadSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section {
            DisclosureGroup("Advanced Debris Spread") {
                VStack(alignment: .leading, spacing: 2) {
                    SliderRow(label: "Tangential (Velocity)",
                              value: $simulation.spreadTangential,
                              range: 0.0...2.0)
                    Text("Stretches the cloud along the orbit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)

                VStack(alignment: .leading, spacing: 2) {
                    SliderRow(label: "Radial (Altitude)",
                              value: $simulation.spreadRadial,
                              range: 0.0...2.0)
                    Text("Changes the apogee and perigee of the orbit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)

                VStack(alignment: .leading, spacing: 2) {
                    SliderRow(label: "Normal (Inclination)",
                              value: $simulation.spreadVertical,
                              range: 0.0...2.0)
                    Text("Spreads debris sideways into new orbital planes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Controls the shape of the debris cloud immediately after satellite destruction.")
        }
    }
}
