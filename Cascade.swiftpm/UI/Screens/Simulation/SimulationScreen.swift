//
//  SimulationScreen.swift
//  Cascade
//
//  Created by Pedro Wiezel on 10/02/26.
//

import SwiftUI
import RealityKit

struct SimulationScreen: View {
    @Bindable var simulation: Simulation
    @State private var showSettings = false

    private let panelWidthRatio = 0.30

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SimulationContainer(simulation: simulation)
                    .ignoresSafeArea()
                    .zIndex(0)

                if simulation.showStats {
                    VStack {
                        Spacer()
                        SimulationMetrics(
                            telemetry: simulation.telemetry,
                            initialSatellites: simulation.initialSatelliteCount,
                            satelliteColor: simulation.satelliteColor,
                            debrisColor: simulation.debrisColor
                        )
                    }
                    .zIndex(1)
                }

                HStack {
                    SimulationControls(
                        isPaused: $simulation.isPaused,
                        showSettings: $showSettings,
                        onResetCamera: { simulation.resetCamera() },
                        onDetonate: { simulation.triggerDetonation() },
                        onRestart: { simulation.resetSimulation() }
                    )
                    Spacer()
                }
                .padding(.leading)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
                .zIndex(2)

                HStack {
                    Spacer()
                    SettingsView(
                        simulation: simulation,
                        onClose: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showSettings = false
                            }
                        }
                    )
                    .frame(width: geometry.size.width * panelWidthRatio)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                    .padding(.vertical)
                    .padding(.trailing)
                    .offset(x: showSettings ? 0 : (geometry.size.width * panelWidthRatio) + 100)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSettings)
                }
                .zIndex(3)
            }
            .onChange(of: showSettings) { _, isOpen in
                updateCameraOffset(isOpen: isOpen, geometry: geometry)
            }
            .onChange(of: geometry.size) { _, _ in
                if showSettings {
                    updateCameraOffset(isOpen: true, geometry: geometry)
                }
            }
        }
    }

    @MainActor
    private func updateCameraOffset(isOpen: Bool, geometry: GeometryProxy) {
        let aspect = geometry.size.width / geometry.size.height
        if isOpen {
            let shiftRatio = (panelWidthRatio / 2.0) * 0.75
            simulation.setSettingsPanel(isOpen: true, ratio: shiftRatio, aspectRatio: Double(aspect))
        } else {
            simulation.setSettingsPanel(isOpen: false, ratio: 0, aspectRatio: Double(aspect))
        }
    }
}
