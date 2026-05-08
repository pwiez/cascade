import SwiftUI

struct ResetActionsSection: View {
    let simulation: Simulation

    @State private var showRestartConfirmation = false

    private var hasPendingChanges: Bool {
        simulation.draft.orbitAltitude != simulation.activeOrbitAltitude ||
        simulation.draft.orbitVariance != simulation.activeOrbitVariance ||
        simulation.draft.useRandomInclination != simulation.activeUseRandomInclination ||
        simulation.draft.satelliteCount != simulation.activeSatelliteCount
    }

    var body: some View {
        Section {
            Button("Reset Defaults") {
                withAnimation { simulation.resetSettingsToDefaults() }
            }
            .foregroundStyle(.blue)

            Button(role: hasPendingChanges ? .none : .destructive) {
                showRestartConfirmation = true
            } label: {
                if hasPendingChanges {
                    LabeledContent("Apply Changes & Restart") {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .foregroundStyle(.yellow)
                    .fontWeight(.semibold)
                } else {
                    Text("Restart Simulation")
                }
            }
            .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                Button("Restart", role: .destructive) {
                    simulation.resetSimulation()
                }
            } message: {
                Text(hasPendingChanges
                     ? "Applying these changes will restart the simulation."
                     : "This will clear satellites and debris, and reset the simulation.")
            }
        }
    }
}
