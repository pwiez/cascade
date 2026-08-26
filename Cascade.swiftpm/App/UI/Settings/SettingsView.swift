//
//  SettingsView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 13/02/26.
//

import CascadeEngine
import SwiftUI

struct SettingsView: View {
    let simulation: Simulation
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                VisualsSection(simulation: simulation)
                TimeScaleSection(simulation: simulation)
                ScenarioSection(simulation: simulation)
                CollisionPhysicsSection(simulation: simulation)
                SpreadSection(simulation: simulation)
                ResetActionsSection(simulation: simulation)
            }
            .navigationTitle("Parameters")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose).bold()
                }
            }
        }
    }
}
