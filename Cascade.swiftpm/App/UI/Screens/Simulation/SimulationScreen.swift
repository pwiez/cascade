//
//  SimulationScreen.swift
//  Cascade
//
//  Created by Pedro Wiezel on 10/02/26.
//

import CascadeEngine
import SwiftUI

/// The simulation tab: the rendered scene, its control rail, the live readout,
/// and the settings panel that slides in from the right.
struct SimulationScreen: View {
    @Bindable var simulation: Simulation

    @State private var showSettings = false
    @State private var viewportSize: CGSize = .zero

    private let panelWidthRatio = 0.30

    /// How far to shift the camera when the panel opens, as a fraction of the
    /// viewport. Half the panel's width, eased back so Earth doesn't slide too far.
    private var cameraShiftRatio: Double { (panelWidthRatio / 2.0) * 0.75 }

    private var panelWidth: CGFloat { viewportSize.width * panelWidthRatio }

    var body: some View {
        ZStack {
            SimulationContainer(simulation: simulation)
                .ignoresSafeArea()
                .zIndex(0)

            if simulation.showStats {
                VStack {
                    Spacer()
                    SimulationMetrics(
                        telemetry: simulation.telemetry,
                        satelliteColor: simulation.settings.satelliteColor,
                        debrisColor: simulation.settings.debrisColor
                    )
                }
                .zIndex(1)
            }

            HStack {
                SimulationControls(
                    isPaused: $simulation.isPaused,
                    showSettings: $showSettings,
                    onResetCamera: simulation.resetCamera,
                    onDetonate: simulation.triggerDetonation,
                    onRestart: simulation.resetSimulation
                )
                Spacer()
            }
            .padding(.leading)
            .frame(maxHeight: .infinity)
            .ignoresSafeArea()
            .zIndex(2)

            HStack {
                Spacer()
                SettingsView(simulation: simulation, onClose: closeSettings)
                    .frame(width: panelWidth)
                    .clipShape(.rect(cornerRadius: DesignTokens.cardRadius))
                    .padding(.vertical)
                    .padding(.trailing)
                    // Parked just off-screen rather than removed, so the panel
                    // keeps its scroll position and its slide stays interruptible.
                    .offset(x: showSettings ? 0 : panelWidth + 100)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSettings)
            }
            .zIndex(3)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        .onChange(of: showSettings) { _, _ in updateCameraOffset() }
        .onChange(of: viewportSize) { _, _ in updateCameraOffset() }
    }

    private func closeSettings() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSettings = false
        }
    }

    private func updateCameraOffset() {
        guard viewportSize.height > 0 else { return }
        simulation.setSettingsPanel(
            isOpen: showSettings,
            ratio: cameraShiftRatio,
            aspectRatio: Double(viewportSize.width / viewportSize.height)
        )
    }
}
