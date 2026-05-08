import SwiftUI

struct ScenarioSection: View {
    @Bindable var simulation: Simulation

    private var hasPendingChanges: Bool {
        simulation.draft.orbitAltitude != simulation.activeOrbitAltitude ||
        simulation.draft.orbitVariance != simulation.activeOrbitVariance ||
        simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ||
        simulation.draft.satelliteCount != simulation.activeSatelliteCount
    }

    var body: some View {
        Section {
            SliderRow(
                label: "Initial Satellites",
                value: $simulation.draft.satelliteCount,
                range: 150...300,
                step: 10,
                format: "%.0f",
                requiresRestart: simulation.draft.satelliteCount != simulation.activeSatelliteCount
            )

            SliderRow(
                label: "Orbit Altitude",
                value: $simulation.draft.orbitAltitude,
                range: 250...320,
                step: 5,
                format: "%.0f Units",
                requiresRestart: simulation.draft.orbitAltitude != simulation.activeOrbitAltitude
            )

            SliderRow(
                label: "Altitude Variance",
                value: $simulation.draft.orbitVariance,
                range: 0...20,
                step: 1,
                format: "±%.0f Units",
                requiresRestart: simulation.draft.orbitVariance != simulation.activeOrbitVariance
            )

            Toggle(isOn: $simulation.draft.useRandomInclination) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Randomize Orbital Planes")
                    Text(simulation.draft.useRandomInclination
                         ? "Satellites will form a shell around Earth."
                         : "Satellites will form a flat ring around Earth.")
                        .font(.caption)
                        .foregroundStyle(simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ? .yellow : .secondary)
                }
            }
            .foregroundStyle(simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ? .yellow : .primary)

        } header: {
            HStack {
                Text("Scenario Setup")
                if hasPendingChanges {
                    Spacer()
                    Text("Restart Pending")
                        .foregroundStyle(.yellow)
                        .font(.default.weight(.regular))
                }
            }
        } footer: {
            if hasPendingChanges {
                Text("Applying these changes will restart the simulation.")
                    .foregroundStyle(.yellow)
            }
        }
    }
}
