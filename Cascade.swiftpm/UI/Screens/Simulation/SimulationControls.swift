import SwiftUI

struct SimulationControls: View {
    @Binding var isPaused: Bool
    @Binding var showSettings: Bool
    let onResetCamera: () -> Void
    let onDetonate: () -> Void
    let onRestart: () -> Void

    @State private var showRestartConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            SimulationButton(
                icon: "burst.fill",
                action: onDetonate,
                isProminent: true,
                tint: .red
            )
            .accessibilityLabel("Detonate Satellite")
            .accessibilityHint("Destroys a satellite and scatters debris into orbit")

            SimulationButton(
                icon: "arrow.triangle.2.circlepath",
                action: { showRestartConfirmation = true },
                isProminent: false,
                tint: .clear
            )
            .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                Button("Restart", role: .destructive, action: onRestart)
            } message: {
                Text("This will clear satellites and debris, and reset the simulation.")
            }
            .accessibilityLabel("Restart Simulation")
            .accessibilityHint("Restarts the simulation")

            SimulationButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                action: { isPaused.toggle() },
                isProminent: false,
                tint: .clear
            )
            .accessibilityLabel(isPaused ? "Resume Simulation" : "Pause Simulation")
            .accessibilityHint(isPaused ? "Resumes the orbital simulation" : "Pauses the orbital simulation")

            SimulationButton(
                icon: "camera.metering.center.weighted",
                action: onResetCamera,
                isProminent: false,
                tint: .clear
            )
            .accessibilityLabel("Reset Camera")
            .accessibilityHint("Returns the camera to its default position")

            SimulationButton(
                icon: "gearshape.fill",
                action: { showSettings.toggle() },
                isProminent: false,
                tint: .clear
            )
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens the simulation parameters panel")
        }
    }
}
