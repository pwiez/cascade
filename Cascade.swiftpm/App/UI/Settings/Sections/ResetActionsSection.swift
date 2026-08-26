import CascadeEngine
import SwiftUI

struct ResetActionsSection: View {
    let simulation: Simulation

    @State private var showRestartConfirmation = false

    var body: some View {
        Section {
            Button("Reset Defaults", action: resetDefaults)
                .foregroundStyle(.blue)

            // No role while a restart is pending: the button is then the way to
            // *apply* the user's edits, not to throw work away.
            Button(role: simulation.hasPendingChanges ? nil : .destructive) {
                showRestartConfirmation = true
            } label: {
                if simulation.hasPendingChanges {
                    LabeledContent("Apply Changes & Restart") {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(.yellow)
                    .bold()
                } else {
                    Text("Restart Simulation")
                }
            }
            .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                Button("Restart", role: .destructive, action: simulation.resetSimulation)
            } message: {
                Text(simulation.hasPendingChanges
                     ? "Applying these changes will restart the simulation."
                     : "This will clear satellites and debris, and reset the simulation.")
            }
        }
    }

    private func resetDefaults() {
        withAnimation {
            simulation.resetSettingsToDefaults()
        }
    }
}
