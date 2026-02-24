//
//  SimulationControls.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI
import TipKit

struct SimulationControls: View {
    @Binding var isPaused: Bool
    @Binding var showSettings: Bool
    let onResetCamera: () -> Void
    let onDetonate: () -> Void
    let onRestart: () -> Void
    
    @State private var showRestartConfirmation = false
    
    let detonateTip = DetonateTip()
    let settingsTip = SettingsTip()
    
    var body: some View {
        VStack(spacing: 16) {
            
            SimulationButton(
                icon: "burst.fill",
                action: onDetonate,
                isProminent: true,
                tint: .red
            )
            .popoverTip(detonateTip, arrowEdge: .leading)
            .accessibilityLabel("Detonate Satellite")
            .accessibilityHint("Destroys a satellite and scatters debris into orbit")
            
            SimulationButton(
                icon: "arrow.triangle.2.circlepath",
                action: { showRestartConfirmation = true },
                isProminent: true,
                tint: .orange
            )
            .popoverTip(detonateTip, arrowEdge: .leading)
            .confirmationDialog("Restart?", isPresented: $showRestartConfirmation) {
                Button("Restart", role: .destructive) {
                    onRestart()
                }
            } message: {
                Text("This will reset all satellites and debris.")
            }
            .accessibilityLabel("Restart Simulation")
            .accessibilityHint("Restarts the simulation")
            
            SimulationButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                action: { isPaused.toggle() },
                isProminent: true,
                tint: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
            .accessibilityLabel(isPaused ? "Resume Simulation" : "Pause Simulation")
            .accessibilityHint(isPaused ? "Resumes the orbital simulation" : "Pauses the orbital simulation")
            
            
            SimulationButton(
                icon: "camera.metering.center.weighted",
                action: onResetCamera,
                isProminent: false,
                tint: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
            .accessibilityLabel("Reset Camera")
            .accessibilityHint("Returns the camera to its default position")
            
            
            SimulationButton(
                icon: "gearshape.fill",
                action: { showSettings.toggle() },
                isProminent: false,
                tint: Color(red: 0.1, green: 0.1, blue: 0.1)
            )
            .popoverTip(settingsTip, arrowEdge: .leading)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens the simulation parameters panel")
        }
    }
}
