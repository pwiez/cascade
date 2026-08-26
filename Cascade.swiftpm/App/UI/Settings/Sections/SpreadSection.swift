import CascadeEngine
import SwiftUI

/// The three axes a debris cloud can be stretched along at the moment of impact.
struct SpreadSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section {
            DisclosureGroup("Advanced Debris Spread") {
                SpreadSliderRow(
                    label: "Tangential (Velocity)",
                    value: $simulation.settings.spreadTangential,
                    explanation: "Stretches the cloud along the orbit."
                )
                SpreadSliderRow(
                    label: "Radial (Altitude)",
                    value: $simulation.settings.spreadRadial,
                    explanation: "Changes the apogee and perigee of the orbit."
                )
                SpreadSliderRow(
                    label: "Normal (Inclination)",
                    value: $simulation.settings.spreadVertical,
                    explanation: "Spreads debris sideways into new orbital planes."
                )
            }
        } footer: {
            Text("Controls the shape of the debris cloud immediately after satellite destruction.")
        }
    }
}
