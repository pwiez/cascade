//
//  ActionsSection.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI

struct ActionsSection: View {
    @ObservedObject var simulation: Simulation
    @State private var showRestartConfirmation = false
    
    var body: some View {
        Section {
            HStack(spacing: 15) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    simulation.resetSettingsToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "slider.horizontal.2.gobackward")
                        Text("Reset Defaults")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.large)
                
                Button(role: .destructive) {
                    showRestartConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                        Text("Respawn")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .confirmationDialog(
                    "Restart Simulation?",
                    isPresented: $showRestartConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Respawn", role: .destructive) {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                        simulation.resetSimulation()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will delete all current debris and reset the simulation parameters.")
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
}