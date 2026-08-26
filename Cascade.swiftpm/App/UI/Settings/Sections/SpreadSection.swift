//
//  SpreadSection.swift
//  Cascade
//
//  Created by Pedro Wiezel on 08/05/26.
//

import CascadeEngine
import SwiftUI

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
