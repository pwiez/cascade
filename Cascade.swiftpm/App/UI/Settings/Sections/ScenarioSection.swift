import CascadeEngine
import SwiftUI

/// Scenario parameters, which only take effect when the universe is rebuilt.
///
/// Every control here edits `draft`; the yellow highlighting is driven by how far
/// `draft` has drifted from the `active` scenario the simulation is running.
struct ScenarioSection: View {
    @Bindable var simulation: Simulation

    private var inclinationChanged: Bool {
        simulation.draft.useRandomInclination != simulation.active.useRandomInclination
    }

    var body: some View {
        Section {
            SliderRow(
                label: "Initial Satellites",
                value: $simulation.draft.satelliteCount,
                range: Scenario.satelliteCountRange,
                step: 25,
                fractionDigits: 0,
                requiresRestart: simulation.draft.satelliteCount != simulation.active.satelliteCount
            )

            SliderRow(
                label: "Orbit Altitude",
                value: $simulation.draft.orbitAltitude,
                range: Scenario.orbitAltitudeRange,
                step: 5,
                fractionDigits: 0,
                unit: " Units",
                requiresRestart: simulation.draft.orbitAltitude != simulation.active.orbitAltitude
            )

            SliderRow(
                label: "Altitude Variance",
                value: $simulation.draft.orbitVariance,
                range: Scenario.orbitVarianceRange,
                step: 1,
                fractionDigits: 0,
                unit: " Units",
                prefix: "±",
                requiresRestart: simulation.draft.orbitVariance != simulation.active.orbitVariance
            )

            Toggle(isOn: $simulation.draft.useRandomInclination) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Randomize Orbital Planes")
                    Text(simulation.draft.useRandomInclination
                         ? "Satellites will form a shell around Earth."
                         : "Satellites will form a flat ring around Earth.")
                        .font(.caption)
                        .foregroundStyle(inclinationChanged ? .yellow : .secondary)
                }
            }
            .foregroundStyle(inclinationChanged ? .yellow : .primary)
        } header: {
            HStack {
                Text("Scenario Setup")
                if simulation.hasPendingChanges {
                    Spacer()
                    Text("Restart Pending")
                        .foregroundStyle(.yellow)
                        .fontWeight(.regular)
                }
            }
        } footer: {
            if simulation.hasPendingChanges {
                Text("Applying these changes will restart the simulation.")
                    .foregroundStyle(.yellow)
            }
        }
    }
}
