//
//  SimulationControls.swift
//  Cascade
//
//  Created by Pedro Wiezel on 16/02/26.
//

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
                title: "Detonate Satellite",
                icon: "burst.fill",
                hint: "Destroys a satellite and scatters debris into orbit",
                isProminent: true,
                tint: .red,
                action: onDetonate
            )

            SimulationButton(
                title: "Restart Simulation",
                icon: "arrow.triangle.2.circlepath",
                hint: "Clears all satellites and debris and starts over",
                action: { showRestartConfirmation = true }
            )
            .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                Button("Restart", role: .destructive, action: onRestart)
            } message: {
                Text("This will clear satellites and debris, and reset the simulation.")
            }

            SimulationButton(
                title: isPaused ? "Resume Simulation" : "Pause Simulation",
                icon: isPaused ? "play.fill" : "pause.fill",
                hint: isPaused ? "Resumes the orbital simulation" : "Pauses the orbital simulation",
                action: { isPaused.toggle() }
            )

            SimulationButton(
                title: "Reset Camera",
                icon: "camera.metering.center.weighted",
                hint: "Returns the camera to its default position",
                action: onResetCamera
            )

            SimulationButton(
                title: "Settings",
                icon: "gearshape.fill",
                hint: "Opens the simulation parameters panel",
                action: { showSettings.toggle() }
            )
        }
    }
}
