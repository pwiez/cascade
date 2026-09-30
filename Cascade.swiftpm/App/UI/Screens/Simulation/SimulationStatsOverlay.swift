//
//  SimulationStatsOverlay.swift
//  Cascade
//

import CascadeEngine
import SwiftUI

/// Keeps settings observation out of the scene and its controls.
struct SimulationStatsOverlay: View {
    let simulation: Simulation

    var body: some View {
        if simulation.showStats {
            VStack {
                Spacer()
                SimulationMetrics(
                    telemetry: simulation.telemetry,
                    satelliteColor: simulation.settings.satelliteColor,
                    debrisColor: simulation.settings.debrisColor
                )
            }
        }
    }
}
